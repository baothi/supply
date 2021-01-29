class AddMoreEdiSettingsToSupplier < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_suppliers, :transmit_orders_to_supplier_via_edi, :boolean, default: false
  end
end
