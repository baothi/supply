class Shopify::DownloadAndCacheEventsWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  include CancellableJob
  include TeamBuildable

  sidekiq_options queue: 'shopify_cache',
                  backtrace: true,
                  retry: false

  attr_accessor :team, :job

  def perform(job_id)
    begin
      @job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
      return if @job.nil?

      @job.initialize_and_begin_job! unless @job.in_progress?
      # Parse options
      num_hours = @job.option_1.to_i
      filter = @job.option_2.to_s
      verb = @job.option_3.to_s

      # Time Period
      params = {
          "updated_at_min": DateTime.now - num_hours.hours
      }.to_json

      build_team
      raise 'Team is nil' if @team.nil?

      # Events
      ShopifyCache::EventService.new(team: @team,
                                     filter: filter,
                                     verb: verb,
                                     params: params).perform
      @job.mark_job_as_complete!
    rescue => ex
      @job.log_error(ex.to_s)
      @job.raise_issue!
      ErrorService.new(exception: ex).perform
      return
    end
  end
end
