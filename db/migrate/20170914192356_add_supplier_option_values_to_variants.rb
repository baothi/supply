class AddSupplierOptionValuesToVariants < ActiveRecord::Migration[6.0]
  def change
    rename_column :spree_variants, :supplier_color_option, :supplier_color_value
    rename_column :spree_variants, :supplier_size_option, :supplier_size_value
    rename_column :spree_variants, :supplier_category_option, :supplier_category_value
  end

  def down
    rename_column :spree_variants, :supplier_color_value, :supplier_color_option
    rename_column :spree_variants, :supplier_size_value, :supplier_size_option
    rename_column :spree_variants, :supplier_category_value, :supplier_category_option
  end
end
