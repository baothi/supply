class AddSupplierProductTypeToProducts < ActiveRecord::Migration[6.0]
  def change
    # We use this as a placeholder for product imports
    add_column :spree_products, :supplier_product_type, :string
  end
end
