class AddCheckproductToSpreeRetailers < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_retailers, :has_product_listing, :boolean, :default => false
  end
end
