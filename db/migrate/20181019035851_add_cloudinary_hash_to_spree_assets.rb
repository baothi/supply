class AddCloudinaryHashToSpreeAssets < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_assets, :cloudinary_hash, :jsonb
  end
end
