class AddSupplierBrandToProduct < ActiveRecord::Migration[6.0]
  def change
    # We use this as a placeholder for product imports - keeping track of the brand of the product
    # We'll later map this to our master list
    add_column :spree_products, :supplier_brand_name, :string
  end
end
