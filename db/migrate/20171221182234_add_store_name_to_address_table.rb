class AddStoreNameToAddressTable < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_addresses, :business_name, :string, after: :lastname
  end
end
