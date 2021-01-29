class AddFreeShippingForSampleProductSettingsToSupplier < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_suppliers, :allow_free_shipping_for_samples, :boolean, default: true
    add_column :spree_suppliers, :num_free_shipping_for_samples_allowed, :integer, default: 3
  end
end
