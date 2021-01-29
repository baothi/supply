class RemoveRetailConnectionFromApplication < ActiveRecord::Migration[6.0]
  def change
    remove_column(:spree_orders, :retail_connection_id, :integer)
    remove_column(:spree_product_listings, :retail_connection_id, :integer)
    remove_column(:spree_variant_listings, :retail_connection_id, :integer)
    remove_column(:spree_retailer_order_reports, :retail_connection_id, :integer)
    remove_column(:spree_reseller_agreements, :retail_connection_id, :integer)
  end
end
