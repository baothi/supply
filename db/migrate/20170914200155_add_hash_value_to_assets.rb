class AddHashValueToAssets < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_assets, :hash_value, :string
  end
end
