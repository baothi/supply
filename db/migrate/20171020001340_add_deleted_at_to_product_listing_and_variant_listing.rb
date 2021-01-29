class AddDeletedAtToProductListingAndVariantListing < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_product_listings, :deleted_at, :datetime
    add_column :spree_variant_listings, :deleted_at, :datetime
  end
end
