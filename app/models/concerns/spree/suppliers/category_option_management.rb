module Spree::Suppliers::CategoryOptionManagement
  extend ActiveSupport::Concern

  included do
    has_many :supplier_category_options
  end

  # Helper to set the time we last run the methods in this concern
  def set_last_updated_categories_at_to_now!
    self.update_column(:last_updated_categories_at, DateTime.now)
  end

  # This method creates Supplier Category Options for this supplier
  # based on all unique values found for the shopify_product_type
  def create_categories_and_shipping_info_from_shopify_product_type!
    # Find all unique Product Categories
    product_categories = Spree::Product.by_supplier(self.id).pluck(:supplier_product_type).uniq

    # Remove Empty ones
    product_categories.reject!(&:blank?)

    # No categories found
    return if product_categories.empty?

    # Create Shipping Categories for each type of product
    product_categories.each do |product_type|
      product_type = product_type.strip # Remove Whitespace

      ActiveRecord::Base.transaction do
        # Create Supplier Category Option (used for automatching etc)
        supplier_category_option = create_supplier_category_option(product_type)

        # Create Shipping Methods
        create_shipping_method(product_type)

        # Create Shipping Category. Eventually Tied to Products
        results = create_shipping_category(product_type)

        # TODO: Optimize this not to make two queries
        # (i.e. create_shipping_method already creates what we need)
        shipping_category = results[1]

        raise 'Shipping Category cannot be null' if
            shipping_category.nil?

        # Now Update all Products!
        Spree::Product.where(
          'supplier_product_type = :supplier_product_type and supplier_id = :supplier_id',
          supplier_id: self.id,
          supplier_product_type:  product_type
        ).update_all(
          shipping_category_id: shipping_category.id,
          supplier_category_option_id: supplier_category_option.id
        )
      end
    end

    self.set_last_updated_categories_at_to_now!
  end

  def create_supplier_category_option(category_name)
    raise 'Category Name is required' if
        category_name.nil?

    category_name = category_name.strip
    # Create Supplier Category Option
    Spree::SupplierCategoryOption.find_or_create_by!(name: category_name,
                                                     supplier: self) do |supplier_category|
      supplier_category.presentation = category_name
    end
  end

  def create_shipping_category(category_name)
    raise 'Category Name is required' if
        category_name.nil?

    category_name = category_name.strip

    # We use the supplier ID because slugs/name may change and we dont want
    # new categories being created
    unique_category_name = "#{self.id} - #{category_name}"
    shipping_category = Spree::ShippingCategory.where(
      name: unique_category_name,
      supplier: self
    ).first_or_create!
    [unique_category_name, shipping_category]
  end

  def create_shipping_method(category_name)
    raise 'Category Name is required' if
        category_name.nil?

    category_name = category_name.strip

    # The zones this supplier has agreed to ship to
    eligible_zones = self.shipping_zones

    return nil if eligible_zones.empty?
    raise 'At least one shipping zone is required' if eligible_zones.nil?

    results = create_shipping_category(category_name)
    unique_category_name = results[0]
    shipping_category = results[1]

    shipping_method =
      Spree::ShippingMethod.where(name: unique_category_name).first_or_create! do |sm|
        code = category_name.gsub(/\s+/, '').upcase
        sm.admin_name = code
        sm.code = code
        calculator = Spree::Calculator::Shipping::CategoryCalculator.new
        sm.calculator = calculator
        sm.shipping_categories << shipping_category
        eligible_zones.each do |eligible_zone|
          sm.zones << eligible_zone
        end
        sm.supplier = self
      end
    shipping_method
  end

  def assign_supplier_products_to_platform_category_options!
    # Get all category options with mappings set on them (i.e. previously mapped)
    Spree::SupplierCategoryOption.for_supplier(self.id).mapped.each do |sco|
      # Now find all the products for this particular supplier category option, and
      # update them with their corresponding Platform Category Option
      Spree::Product.with_supplier_category_mapping(sco.id).each do |product|
        product.update_column(:platform_category_option_id, sco.platform_category_option&.id)
        # Now assign to taxon if doesn't already exist
        product.refresh_taxons_based_on_platform!
      end
    end
  end
end
