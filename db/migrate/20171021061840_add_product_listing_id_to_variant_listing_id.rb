class AddProductListingIdToVariantListingId < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_variant_listings, :product_listing_id, :integer
    add_index :spree_variant_listings, :product_listing_id
  end
end
