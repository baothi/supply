class ChangeFriendlyNameToDisplayNameOnSpreeSuppliers < ActiveRecord::Migration[6.0]
  def change
    rename_column :spree_suppliers, :friendly_name, :display_name
  end
end
