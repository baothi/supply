class AddIndexToAssetHash < ActiveRecord::Migration[6.0]
  def change
    add_index :spree_assets, :hash_value
  end
end
