module Spree::Retailers::SellingPermissionScope
  extend ActiveSupport::Concern

  included do
    has_many :selling_authorities, dependent: :destroy

    has_many :permit_selling_authorities,
             -> { where(permission: :permit) },
             class_name: 'Spree::SellingAuthority'

    has_many :reject_selling_authorities,
             -> { where(permission: :reject) },
             class_name: 'Spree::SellingAuthority'

    has_many :white_listed_products,
             through: :permit_selling_authorities,
             source: :permittable,
             source_type: 'Spree::Product'

    has_many :black_listed_products,
             through: :reject_selling_authorities,
             source: :permittable,
             source_type: 'Spree::Product'

    has_many :white_listed_suppliers,
             through: :permit_selling_authorities,
             source: :permittable,
             source_type: 'Spree::Supplier'

    has_many :black_listed_suppliers,
             through: :reject_selling_authorities,
             source: :permittable,
             source_type: 'Spree::Supplier'
  end

  def can_access_product?(product)
    !(all_blocked_product_ids.include?(product.internal_identifier) ||
      all_blocked_supplier_ids.include?(product.supplier.internal_identifier))
  end

  def can_access_supplier?(supplier)
    !all_blocked_supplier_ids.include?(supplier.internal_identifier)
  end

  # Black-listed products and products whitelisted for other retailer(s)
  def all_blocked_product_ids
    (black_listed_product_ids + products_white_listed_for_others).uniq
  end

  # Black-listed products and products whitelisted for other retailer(s)
  def all_blocked_supplier_ids
    (black_listed_supplier_ids + suppliers_white_listed_for_others).uniq
  end

  def black_listed_product_ids
    black_listed_products.pluck(:internal_identifier)
  end

  def products_white_listed_for_others
    products_with_permit_authority - white_listed_product_ids
  end

  # Products that are whitelisted for some retailer. Have permit authority linked
  def products_with_permit_authority
    Spree::Product.has_permit_selling_authority.pluck(:internal_identifier)
  end

  def white_listed_product_ids
    white_listed_products.pluck(:internal_identifier)
  end

  def black_listed_supplier_ids
    black_listed_suppliers.pluck(:internal_identifier)
  end

  def suppliers_white_listed_for_others
    suppliers_with_permit_authority - white_listed_supplier_ids
  end

  # Suppliers that are whitelisted for some retailer. Have permit authority linked
  def suppliers_with_permit_authority
    Spree::Supplier.has_permit_selling_authority.pluck(:internal_identifier)
  end

  def white_listed_supplier_ids
    white_listed_suppliers.pluck(:internal_identifier)
  end

  class_methods do
    def select2_search(q)
      query = select(:id, :name).
              where('name iLIKE (:q) OR shopify_url iLIKE (:q)', q: "%#{q}%").limit(20)

      {
        results: query.map do |e|
          {
            text: e.name,
            id: e.id.to_s
          }
        end,
        paginate: { more: true }
      }
    end
  end
end
