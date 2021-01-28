module Spree::Variants::ColorOptionable
  extend ActiveSupport::Concern

  included do
    belongs_to :platform_color_option
    belongs_to :supplier_color_option

    scope :with_supplier_color_mapping, ->(supplier_color_option_id) {
      where('spree_variants.supplier_color_option_id = :supplier_color_option_id',
            supplier_color_option_id: supplier_color_option_id)
    }

    scope :not_mapped_to_platform_color, -> {
      where('spree_variants.platform_color_option_id is NULL')
    }

    scope :mapped_to_platform_color, -> {
      where('spree_variants.platform_color_option_id is not NULL')
    }
  end

  def create_supplier_color_option(color_name)
    raise 'Color Name is required' if
        color_name.nil?

    return if self.supplier.nil?

    original_color_name = color_name&.strip&.upcase
    parameterized_name = original_color_name.parameterize
    # Create Supplier Color Option
    sco = Spree::SupplierColorOption.find_or_create_by!(name: parameterized_name,
                                                        supplier: self.supplier) do |supplier_color|
      supplier_color.presentation = original_color_name
    end
    sco
  end
end
