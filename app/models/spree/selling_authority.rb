class Spree::SellingAuthority < ApplicationRecord
  attr_accessor :permittable_string

  belongs_to :retailer, class_name: 'Spree::Retailer'
  belongs_to :permittable, polymorphic: true

  enum permission: { permit: 'permit', rejected: 'reject' }

  before_validation :set_permittable

  validates :retailer, :permittable, :permission, presence: true
  validates :retailer, uniqueness: { scope: %i(permittable_type permittable_id) }

  def set_permittable
    return if permittable_string.nil?

    type, id = permittable_string.split(' ')
    self.permittable = type.constantize.find_by(id: id.to_i)
  end

  def permittable_getter
    "#{permittable_type} #{permittable_id}"
  end

  def self.current_permittable_opts(edit_id)
    current = find_by(id: edit_id)

    {
      text: current.permittable.name,
      id: current.permittable_getter,
      selected: true
    }
  end

  def self.permittable_opts(q)
    supplier_query = Spree::Supplier.select(:id, :name).
                     where('name iLIKE (:q) OR shopify_url iLIKE (:q)', q: "%#{q}%").limit(15)
    products_query = Spree::Product.select(:id, :name).where('name iLIKE (?)', "%#{q}%").limit(15)

    format_select2_data(supplier_query, products_query)
  end

  def self.format_select2_data(supplier_query, products_query)
    {
      results: [
        {
          text: 'Supplier',
          children: supplier_query.map do |e|
            {
              text: e.name,
              id: "Spree::Supplier #{e.id}"
            }
          end
        },
        {
          text: 'Products',
          children: products_query.map do |e|
            {
              text: e.name,
              id: "Spree::Product #{e.id}"
            }
          end
        }
      ],
      paginate: { more: true }
    }
  end
end
