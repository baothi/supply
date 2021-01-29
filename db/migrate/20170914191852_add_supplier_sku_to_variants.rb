class AddSupplierSkuToVariants < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_variants, :supplier_sku, :string
    add_index :spree_variants, :supplier_sku
  end
end
