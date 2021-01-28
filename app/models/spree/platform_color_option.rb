class Spree::PlatformColorOption < ApplicationRecord
  include InternalIdentifiable
  include Strippable

  before_save :strip_name
  before_save :strip_presentation

  has_many :supplier_color_options
  has_many :variants

  validates :name, presence: true, uniqueness: true
end
