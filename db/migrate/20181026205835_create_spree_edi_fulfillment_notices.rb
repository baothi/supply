class CreateSpreeEdiFulfillmentNotices < ActiveRecord::Migration[6.0]
  def change
    create_table :spree_edi_fulfillment_notices do |t|
      t.string :asn_number
      t.datetime :asn_generated_at
      t.string :sender_name
      t.string :sender_identifier
      t.string :purchase_order_number
      t.string :carrier_name
      t.string :scac_code
      t.date :po_created_at
      t.date :estimated_delivery_date
      t.date :shipped_date
      t.string :customer_order_number
      t.string :internal_vendor_number
      t.integer :num_items
      t.text :raw_xml
      t.timestamps
    end
  end
end
