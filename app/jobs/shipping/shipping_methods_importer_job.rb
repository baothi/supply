module Shipping
  class ShippingMethodsImporterJob < ApplicationJob
    include ImportableJob
    queue_as :exports

    def perform(job_id)
      job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
      job.initialize_and_begin_job! unless job.in_progress?

      supplier = Spree::Supplier.find_by(id: job.supplier_id)

      begin
        contents = extract_data_from_job_file(job)
      rescue => e
        job.log_error(e.to_s)
        JobsMailer.shopify_csv_upload_error(job.id).deliver_now
        return
      end

      mapping = Spree::ShippingMethod::CSV_MAPPING
      job.update(total_num_of_records: contents.count)

      contents.each do |attributes|
        shipping_method = supplier.shipping_methods.find_by(
          name: attributes.delete('Shipping Method Name')
        )
        next unless shipping_method.present?

        attributes.each do |key, value|
          shipping_method.calculator.set_preference(mapping.key(key), value)
          shipping_method.save
          job.update_status(true)
        end
      end
    end
  end
end
