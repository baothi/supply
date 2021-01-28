class Spree::SupplierLicenseOption < ApplicationRecord
  include Strippable
  include InternalIdentifiable

  belongs_to :platform_color_option

  belongs_to :supplier
  validates :supplier, presence: true

  before_save :strip_name
  before_save :strip_presentation

  has_many :variants, dependent: :nullify

  scope :for_supplier, ->(supplier_id) {
    where('spree_supplier_license_options.supplier_id = :supplier_id',
          supplier_id: supplier_id)
  }
end
