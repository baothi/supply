module Shopify
  class OrderGenerationJob < ApplicationJob
    queue_as :order_export

    def perform(job_id)
      begin
        @job = Spree::LongRunningJob.find(job_id)
        @job.initialize_and_begin_job! unless @job.in_progress?
      rescue => e
        @job.log_error(e.to_s)
        @job.raise_issue!
        return
      end

      begin
        generator = Testing::ShopifyOrderGenerator.new(job_id)
        generator.perform

        puts "Generated #{generator.successful_orders} orders!".green
        @job.mark_job_as_complete!
      rescue => e
        @job.log_error(e.message.to_s)
        puts "Error Generating orders".red
        @job.raise_issue!
      end        
    end
  end
end
