module Products
  class ProductCacheRefreshJob < ApplicationJob
    include Emailable

    queue_as :exports

    def perform(job_id)
      begin
        @job = Spree::LongRunningJob.find_by(internal_identifier: job_id)

        @job.initialize_and_begin_job! unless @job.in_progress?

        Spree::Product.refresh_indices!

        puts 'Completed Refreshing Indices'.green

        subject = "[Product Cache] Completed Refresh at #{DateTime.now}"
        body = 'All products have been cached. They should now be searchable as a retailer.'

        email_results_to_operations!(subject, body)

        @job.complete_job!
      rescue => ex
        puts "#{ex}".red
        @job.log_error(ex) if @job.present?
      end
    end
  end
end
