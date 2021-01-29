class AddAddressToSupplierAndRetailer < ActiveRecord::Migration[6.0]
  def change
    # Retailers
    add_column :spree_retailers, :address1, :string
    add_column :spree_retailers, :address2, :string
    add_column :spree_retailers, :city, :string
    add_column :spree_retailers, :zipcode, :string
    add_column :spree_retailers, :state, :string
    add_column :spree_retailers, :country, :string
    add_column :spree_retailers, :phone, :string

    # Suppliers
    add_column :spree_suppliers, :address1, :string
    add_column :spree_suppliers, :address2, :string
    add_column :spree_suppliers, :city, :string
    add_column :spree_suppliers, :zipcode, :string
    add_column :spree_suppliers, :state, :string
    add_column :spree_suppliers, :country, :string
    add_column :spree_suppliers, :phone, :string
  end
end
