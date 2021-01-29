class AddSettingsToProducts < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_products, :settings, :jsonb, null: false, default: {}
  end
end
