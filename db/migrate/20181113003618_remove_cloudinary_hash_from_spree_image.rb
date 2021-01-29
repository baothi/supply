class RemoveCloudinaryHashFromSpreeImage < ActiveRecord::Migration[6.0]
  def change
    remove_column :spree_assets, :cloudinary_hash, :jsonb

    add_column :spree_assets, :previous_image_id, :integer
  end
end
