class AddSettingsToSuppliers < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_suppliers, :settings, :jsonb, default: {}
  end
end
