class AddCityStateToAddresses < ActiveRecord::Migration[6.0]
  def change
    # We want to circumvent Spree's mechanism
    add_column :spree_addresses, :name_of_state, :string
  end
end
