module Dsco
  module Product
    class BatchImportJob < ApplicationJob
      include ImportableJob
      queue_as :shopify_import
      def perform(job_id)
        @job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
        @job.initialize_and_begin_job! unless @job.in_progress?

        begin
         @supplier = Spree::Supplier.find(@job.supplier_id)
       rescue => e
         @job.log_error(e.to_s)
         @job.raise_issue!
         return
       end
        import_products
        @job.complete_job! if @job.may_complete_job?
      end

      def import_products
        sheet_rows = extract_data_from_job_file(@job)
        total_records = sheet_rows.count
        @job.update(total_num_of_records: total_records)
        dsco_importer = Dsco::Product::Importer.new(@supplier)
        sheet_rows.each_with_index do |row, index|
          begin
            status = dsco_importer.perform(row.with_indifferent_access)
            @job.update_status(status)
            break if Rails.env.development? && (index >= 10)
          rescue => e
            @job.log_error(e.to_s)
          end
        end

        # Skip development
        unless Rails.env.development?
          import_images(dsco_importer.processed_products_ids)
        end
      end

      def import_images(product_ids)
        product_ids.each do |product_id|
          job = create_image_download_job(product_id)
          Shopify::ImportProductImageJob.perform_later(job.internal_identifier)
        end
      end

      def create_image_download_job(product_id)
        Spree::LongRunningJob.create(
          action_type: 'import',
          job_type: 'images_import',
          initiated_by: 'user',
          option_1: product_id
        )
      end
    end
  end
end
