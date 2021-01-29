class AddStoreNameAndStoreOwnerToRetailersAndSuppliers < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_retailers, :shop_owner, :string
    add_column :spree_suppliers, :shop_owner, :string
  end
end
