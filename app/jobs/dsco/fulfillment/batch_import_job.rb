module Dsco
  module Fulfillment
    class BatchImportJob < ApplicationJob
      include ImportableJob
      def perform(job_id)
        @job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
        @job.initialize_and_begin_job! unless @job.in_progress?

        begin
          import_fulfillments
        rescue => e
          @job.log_error(e.to_s)
        end

        @job.complete_job! if @job.may_complete_job?
      end

      def import_fulfillments
        contents = extract_data_from_job_file(@job)
        raise 'Could not get data from job file' unless contents.present?

        fulfillments = contents.map(&:to_hash)

        return if fulfillments.blank? || fulfillments.empty?

        dsco_fulfillments = fulfillments.map(&:to_open_struct)

        valid_fulfillments = Dsco::Fulfillment::Filterer.new(dsco_fulfillments).perform
        return unless valid_fulfillments.present?

        @job.update(total_num_of_records: valid_fulfillments.count)

        valid_fulfillments.each do |fulfillment|
          begin
            local_line_item = get_local_line_item(fulfillment)
            status = local_line_item.fulfill_shipment(fulfillment.package_tracking_number)
            export_fulfillment(local_line_item) if status
            @job.update_status(status)
          rescue => e
            @job.log_error(e.to_s)
            @job.update_status(false)
          end
        end
      end

      def get_local_line_item(fulfillment)
        # First find local variant
        # local_variant = Spree::Variant.find_by(dsco_identifier: fulfillment.dsco_item_id)
        local_variant = Spree::Variant.find_by(original_supplier_sku: fulfillment.line_item_sku&.upcase)
        order = Spree::Order.find_by(number: fulfillment.po_number)

        local_line_item = order.line_items.where(
          variant_id: local_variant.id
        ).first
        local_line_item
      end

      def export_fulfillment(local_line_item)
        begin
          order = local_line_item.order
          return if order.source == 'app'

          export_job = Spree::LongRunningJob.create(
            action_type: 'export',
            job_type: 'orders_export',
            initiated_by: 'system',
            option_1: order.internal_identifier,
            retailer_id: order.retailer_id
          )
          ShopifyFulfillmentExportJob.perform_later(export_job.internal_identifier)
        rescue
          @job.log_error("Could not auto export imported fulfillment \n")
        end
      end
    end
  end
end

class Hash
  def to_open_struct
    OpenStruct.new(self)
  end
end
