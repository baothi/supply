module Spree::Products::SellingPermissionScope
  extend ActiveSupport::Concern

  included do
    has_many :selling_authorities, as: :permittable, dependent: :destroy

    has_many :permit_selling_authorities,
             -> { where(permission: :permit) },
             as: :permittable,
             class_name: 'Spree::SellingAuthority'

    has_many :reject_selling_authorities,
             -> { where(permission: :reject) },
             as: :permittable,
             class_name: 'Spree::SellingAuthority'

    has_many :white_listed_retailers,
             through: :permit_selling_authorities,
             source: :retailer

    has_many :black_listed_retailers,
             through: :reject_selling_authorities,
             source: :retailer

    scope :has_permit_selling_authority, -> {
      joins(:permit_selling_authorities)
    }

    scope :has_reject_selling_authority, -> {
      joins(:reject_selling_authorities)
    }
  end
end
