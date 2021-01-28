class Spree::Webhook < ApplicationRecord
  belongs_to :teamable, polymorphic: true
end
