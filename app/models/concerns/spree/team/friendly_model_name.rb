module Spree::Team::FriendlyModelName
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
  end

  def friendly_model_name
    self.class.to_s.tap { |s| s.slice!('Spree::') }.downcase
  end
end
