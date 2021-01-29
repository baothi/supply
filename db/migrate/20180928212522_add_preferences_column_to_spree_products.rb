class AddPreferencesColumnToSpreeProducts < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_products, :preferences, :jsonb
  end
end
