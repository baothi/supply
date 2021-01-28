module FlipperIdentifiable
  extend ActiveSupport::Concern

  def flipper_id
    self.to_global_id.to_s if respond_to?(:to_global_id)
  end
end
