class Spree::PlatformCategoryOption < ApplicationRecord
  include InternalIdentifiable
  include Strippable

  before_save :strip_name
  before_save :strip_presentation

  has_many :supplier_category_options
  has_many :products

  validates :name, presence: true, uniqueness: true
end
