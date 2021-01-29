class AddSettingsToRetailer < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_retailers, :settings, :jsonb, default: {}
  end
end
