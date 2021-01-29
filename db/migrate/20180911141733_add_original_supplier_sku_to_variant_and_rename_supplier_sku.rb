class AddOriginalSupplierSkuToVariantAndRenameSupplierSku < ActiveRecord::Migration[6.0]
  def change
    rename_column :spree_variants, :supplier_sku, :original_supplier_sku
    add_column :spree_variants, :platform_supplier_sku, :string

    add_index :spree_variants, :platform_supplier_sku
  end
end
