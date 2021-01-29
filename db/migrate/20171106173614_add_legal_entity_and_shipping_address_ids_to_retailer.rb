class AddLegalEntityAndShippingAddressIdsToRetailer < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_retailers, :legal_entity_address_id, :integer,
                foreign_key: { to_table: 'spree_addresses' }
    add_column :spree_retailers, :shipping_address_id, :integer,
                foreign_key: { to_table: 'spree_addresses' }
  end
end
