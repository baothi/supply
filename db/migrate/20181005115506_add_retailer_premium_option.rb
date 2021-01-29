class AddRetailerPremiumOption < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_retailers,
               :can_view_supplier_name, :boolean, default: false
    add_column :spree_retailers,
               :can_view_brand_name, :boolean, default: false
  end
end
