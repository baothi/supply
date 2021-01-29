class AddSupplierOptionsToVariants < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_variants, :supplier_color_option, :string
    add_column :spree_variants, :supplier_size_option, :string
    add_column :spree_variants, :supplier_category_option, :string
  end
end
