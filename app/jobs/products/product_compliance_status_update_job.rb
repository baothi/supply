module Products
  class ProductComplianceStatusUpdateJob < ApplicationJob
    include Emailable

    queue_as :exports

    def perform(job_id)
      begin
        @job = Spree::LongRunningJob.find_by(internal_identifier: job_id)

        @job.initialize_and_begin_job! unless @job.in_progress?

        start_id = @job.option_1
        end_id = @job.option_2
        batch_number = @job.option_3
        supplier_id = @job.supplier_id
        supplier = Spree::Supplier.find(supplier_id) unless supplier_id.nil?

        puts "Updating Product Compliance for Products Between: #{start_id} & #{end_id}".yellow

        Spree::Product.find_each(start: start_id, finish: end_id) do |p|
          begin
            p.update_product_compliance_status!
          rescue => ex
            puts "#{ex}".red
            puts "We ran into an issue updating counter for #{p}"
          end
        end

        if supplier
          subject = "[Compliance Update] Batch ##{batch_number} for #{supplier.name} completed"
          body = "The platform has completed updating compliance for batch #{batch_number} for "\
          "#{supplier.name}."
        else
          subject = "[Compliance Update] Batch ##{batch_number} completed"
          body = "The platform has completed updating compliance for batch #{batch_number}."
        end

        email_results_to_operations!(subject, body)

        puts "Completed #{start_id} - #{end_id}".green

        @job.complete_job!
      rescue => ex
        puts "#{ex}".red
        @job.log_error(ex) if @job.present?
      end
    end
  end
end
