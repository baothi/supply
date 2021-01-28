module Spree::Products::SizeOptionable
  extend ActiveSupport::Concern

  def guess_size_option_type
    option_types.each do |ot|
      return ot if ot.name.downcase.include?('size') ||
                   ot.name.downcase.include?('model')
    end
    # We don't want this method to return the option_types array
    nil
  end

  def create_supplier_size_options_from_existing_values!
    self.variants.each do |v|
      # We do this to try to create size options for situations where values
      # are already there
      # This will only create a new supplier_size_option if one doesn't exist prior
      if v.supplier_size_value.present?
        size_name = v.supplier_size_value
        supplier_size_option =
          set_and_create_supplier_size_option_based_on_existing_value_if_not_existing(
            v, size_name
          )
        v.update_columns(
          supplier_size_option_id: supplier_size_option.id
        )
        next
      end
    end
  end

  def set_and_create_supplier_size_option_based_on_existing_value_if_not_existing(v, size_name)
    v.create_supplier_size_option(size_name)
  end

  def set_approximate_size_based_on_option_type!
    size_option_type = self.guess_size_option_type
    return if size_option_type.nil?

    # If we make it here, we have a high likelihood
    # of using the correct option_type

    self.variants.each do |v|
      # No need to guess for variants that already have a supplier_size_value present
      next if v.supplier_size_value.present?

      # Set the size type on each variants
      variant_size = v.option_values.where(option_type_id: size_option_type.id).first
      puts "Variant #{v.id}:  Variant Size: #{variant_size.name}".blue

      size_name = variant_size.name
      ActiveRecord::Base.transaction do
        # First Create the Color Option Type
        supplier_size_option = v.create_supplier_size_option(size_name)

        v.update_columns(
          supplier_size_value: size_name,
          supplier_size_option_id: supplier_size_option.id
        )
      end
    end
  end
end
