class AddFulfillmentConversionDatesToRetailer < ActiveRecord::Migration[6.0]
  def change
    # Used for transition to Hingeto Fulfillment
    add_column :spree_retailers, :hingeto_fulfillment_service_created_at, :datetime
    add_column :spree_retailers, :shopify_management_switched_to_hingeto_at, :datetime
    add_column :spree_variant_listings, :shopify_management_switched_to_hingeto_at, :datetime
  end
end
