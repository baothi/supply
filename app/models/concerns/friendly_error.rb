module FriendlyError
  extend ActiveSupport::Concern

  included do
  end

  def friendly_error
    self.errors.full_messages.flatten.join('. ')
  end

  class_methods do
  end
end
