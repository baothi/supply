module Spree::Suppliers::ColorOptionManagement
  extend ActiveSupport::Concern

  included do
    has_many :supplier_color_options
  end

  # Helper to set the time we last run the methods in this concern
  def set_last_updated_categories_at_to_now!
    self.update_column(:last_updated_colors_at, DateTime.now)
  end

  def create_colors_from_option_types!
    Spree::Product.by_supplier(self.id).find_each do |p|
      begin
        p.set_approximate_color_based_on_option_type!
        p.create_supplier_color_options_from_existing_values!
      rescue => ex
        puts "#{ex}".red
      end
    end
  end

  # This essentially automatches
  def assign_supplier_products_to_platform_color_options!
    count = 0
    # Get all category options with mappings set on them (i.e. previously mapped)
    Spree::SupplierColorOption.for_supplier(self.id).mapped.each do |sco|
      # Now find all the products for this particular supplier category option, and
      # update them with their corresponding Platform Category Option
      Spree::Variant.with_supplier_color_mapping(sco.id).each do |variant|
        variant.update_column(:platform_color_option_id, sco.platform_color_option&.id)
        count = count + 1
      end
    end
    count
  end
end
