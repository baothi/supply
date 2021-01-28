module Products
  class ProductCounterJob < ApplicationJob
    queue_as :exports

    def perform(job_id)
      begin
        @job = Spree::LongRunningJob.find_by(internal_identifier: job_id)

        @job.initialize_and_begin_job! unless @job.in_progress?

        start_id = @job.option_1
        end_id = @job.option_2

        puts "Updating Image Count for Products Between: #{start_id} & #{end_id}".yellow

        Spree::Product.find_each(start: start_id, finish: end_id) do |p|
          begin
            p.update_image_counter!
          rescue => ex
            puts "#{ex}".red
            puts "We ran into an issue updating coounter for #{p}"
            # TODO: Add Rollbar Notifier
          end
        end

        puts "Completed #{start_id} - #{end_id}".green

        @job.complete_job!
      rescue => ex
        puts "#{ex}".red
        @job.log_error(ex) if @job.present?
      end
    end
  end
end
