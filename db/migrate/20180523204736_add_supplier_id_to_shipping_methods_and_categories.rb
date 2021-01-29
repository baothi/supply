class AddSupplierIdToShippingMethodsAndCategories < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_shipping_categories, :supplier_id, :integer, index: true
    add_column :spree_shipping_methods, :supplier_id, :integer, index: true
  end
end
