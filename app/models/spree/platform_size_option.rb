class Spree::PlatformSizeOption < ApplicationRecord
  include InternalIdentifiable
  include Strippable
  include SizeNameable

  before_validation :set_name
  before_validation :strip_name
  before_validation :strip_presentation

  has_many :supplier_size_options
  has_many :variants

  validates :name, presence: true, uniqueness: true

  def set_name
    self.name = combined_size_name(self.name_1, self.name_2).parameterize if
        self.name.blank?
  end
end
