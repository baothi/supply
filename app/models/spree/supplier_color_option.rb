class Spree::SupplierColorOption < ApplicationRecord
  include Strippable
  include InternalIdentifiable

  belongs_to :platform_color_option

  belongs_to :supplier
  validates :supplier, presence: true

  before_save :strip_name
  before_save :strip_presentation

  has_many :variants, dependent: :nullify

  scope :mapped, -> {
    where('spree_supplier_color_options.platform_color_option_id is not null')
  }

  scope :not_mapped, -> {
    where('spree_supplier_color_options.platform_color_option_id is null')
  }

  scope :for_supplier, ->(supplier_id) {
    where('spree_supplier_color_options.supplier_id = :supplier_id',
          supplier_id: supplier_id)
  }
end
