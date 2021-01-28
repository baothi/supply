class Spree::SupplierCategoryOption < ApplicationRecord
  include Strippable
  include InternalIdentifiable

  belongs_to :platform_category_option

  belongs_to :supplier
  validates :supplier, presence: true

  before_save :strip_name
  before_save :strip_presentation

  has_many :products, dependent: :nullify

  scope :mapped, -> {
    where('spree_supplier_category_options.platform_category_option_id is not null')
  }

  scope :not_mapped, -> {
    where('spree_supplier_category_options.platform_category_option_id is null')
  }

  scope :for_supplier, ->(supplier_id) {
    where('spree_supplier_category_options.supplier_id = :supplier_id',
          supplier_id: supplier_id)
  }
end
