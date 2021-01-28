module Products
  class ProductSearchAttributesRefreshJob < ApplicationJob
    include Emailable

    queue_as :exports

    def perform(job_id)
      begin
        @job = Spree::LongRunningJob.find_by(internal_identifier: job_id)

        @job.initialize_and_begin_job! unless @job.in_progress?

        start_id = @job.option_1
        end_id = @job.option_2

        Spree::Product.build_search_attributes_for!(start_id: start_id, end_id: end_id)

        puts 'Completed Rebuilding Search Attributes'.green

        @job.complete_job!
      rescue => ex
        puts "#{ex}".red
        @job.log_error(ex) if @job.present?
      end
    end
  end
end
