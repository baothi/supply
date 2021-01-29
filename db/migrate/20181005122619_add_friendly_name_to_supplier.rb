class AddFriendlyNameToSupplier < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_suppliers, :friendly_name, :string
  end
end
