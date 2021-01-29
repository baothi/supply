class AddSupplierIdToProduct < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_products, :supplier_id, :integer
    add_column :spree_variants, :supplier_id, :integer
  end
end
