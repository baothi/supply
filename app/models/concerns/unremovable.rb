# This concern is not typically necessary if the model is a paranoid one (i.e. uses paranoia gem)
# It can still be used if the model including it belongs to a paranoid one, and we
# want to ensure it is not removed (e.g. Asset/Image)
module Unremovable
  extend ActiveSupport::Concern

  included do
    before_destroy :disable_destroy
  end

  def disable_destroy
    errors.add(:base, 'Sorry. Deletion not allowed')
    false
  end
end
