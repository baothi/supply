module Spree::Products::ColorOptionable
  extend ActiveSupport::Concern

  def guess_color_option_type
    option_types.each do |ot|
      return ot if ot.name.downcase.include? 'color'
    end
    # We don't want this method to return the option_types array
    nil
  end

  def set_approximate_color_based_on_option_type!
    color_option_type = self.guess_color_option_type
    return if color_option_type.nil?

    # If we make it here, we have a high likelihood
    # of using the correct option_type

    self.variants.each do |v|
      # No need to guess for variants that already have a supplier_color_value present
      next if v.supplier_color_value.present?

      # Set the color type on each variants
      variant_color = v.option_values.where(option_type_id: color_option_type.id).first
      puts "Variant #{v.id}:  Variant Color: #{variant_color.name}".blue

      color_name = variant_color.name
      ActiveRecord::Base.transaction do
        # First Create the Color Option Type
        supplier_color_option = v.create_supplier_color_option(color_name)

        v.update_columns(
          supplier_color_value: color_name,
          supplier_color_option_id: supplier_color_option.id
        )
      end
    end
  end

  def create_supplier_color_options_from_existing_values!
    self.variants.each do |v|
      # We do this to try to create color options for situations where values
      # are already there
      # This will only create a new supplier_color_option if one doesn't exist prior
      if v.supplier_color_value.present?
        color_name = v.supplier_color_value
        supplier_color_option =
          set_and_create_supplier_color_option_based_on_existing_value_if_not_existing(
            v, color_name
          )
        v.update_columns(
          supplier_color_option_id: supplier_color_option.id
        )
        next
      end
    end
  end

  def set_and_create_supplier_color_option_based_on_existing_value_if_not_existing(v, color_name)
    v.create_supplier_color_option(color_name)
  end
end
