class AddFulfillmentSentToRetailerAtToLineItem < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_line_items, :fulfillment_sent_to_retailer_at, :datetime
  end
end
