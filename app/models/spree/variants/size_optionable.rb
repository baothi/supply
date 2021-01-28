module Spree::Variants::SizeOptionable
  extend ActiveSupport::Concern

  include SizeNameable

  included do
    belongs_to :platform_size_option
    belongs_to :supplier_size_option

    scope :with_supplier_size_mapping, ->(supplier_size_option_id) {
      where('spree_variants.supplier_size_option_id = :supplier_size_option_id',
            supplier_size_option_id: supplier_size_option_id)
    }

    scope :not_mapped_to_platform_size, -> {
      where('spree_variants.platform_size_option_id is NULL')
    }

    scope :mapped_to_platform_size, -> {
      where('spree_variants.platform_size_option_id is not NULL')
    }
  end

  def create_supplier_size_option(first_name, second_name = nil)
    raise 'Supplier Size Name is required' if
        first_name.nil?

    return if self.supplier.nil?

    original_size_name = combined_size_name(first_name, second_name)
    parameterized_name = original_size_name.parameterize
    # Create Supplier Size Option
    sso = Spree::SupplierSizeOption.find_or_create_by!(name: parameterized_name,
                                                       supplier: self.supplier) do |supplier_size|
      supplier_size.presentation = original_size_name
    end
    sso
  end
end
