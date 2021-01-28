module TeamBuildable
  extend ActiveSupport::Concern
  included do
  end

  def build_team
    @team = @job.teamable_type.constantize.find(@job.teamable_id)
  end
end
