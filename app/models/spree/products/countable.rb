module Spree::Products::Countable
  extend ActiveSupport::Concern

  included do
  end

  class_methods do
    # We chose 250 arbitrarily - model after Shopify
    def update_all_image_counters!(start, finish, batch_size = 250)
      ro = ResponseObject.blank_success_response_object
      begin
        raise 'Finish must be larger than start value' if start > finish

        num_batches = ((finish - start) / batch_size.to_f).ceil
        current_start = start
        current_finish = start + batch_size
        (1..num_batches).each do
          # Create Job
          job = image_counter_job(current_start, current_finish)
          ::Products::ProductCounterJob.perform_later(job.internal_identifier)

          # Now line up remaining
          current_start = current_finish
          current_finish = current_finish + batch_size

          # Limit upper bound
          if current_finish >= finish
            current_finish = finish
          end
        end
        ro.message = 'Successfully queued jobs to calculate updated counter cache'
      rescue => ex
        ro.fail_with_exception!(ex)
      end
      ro
    end

    def image_counter_job(start, finish)
      Spree::LongRunningJob.create(
        action_type: 'import',
        job_type: 'image_counter',
        initiated_by: 'user',
        option_1: start,
        option_2: finish
      )
    end
  end

  # Instance Methods

  def update_image_counter!
    self.update_columns(image_counter: self.images.count,
                        last_updated_image_counter_at: DateTime.now)
  end
end
