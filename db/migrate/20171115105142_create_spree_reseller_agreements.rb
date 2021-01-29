class CreateSpreeResellerAgreements < ActiveRecord::Migration[6.0]
  def change
    create_table :spree_reseller_agreements do |t|
      t.references :retailer
      t.references :supplier
      t.belongs_to :retail_connection,
                   foreign_key: { to_table: :spree_retail_connections },
                   index: { :name => "index_reseller_agreement_signs_on_spree_retail_conns_id" }
      t.string :signature_request_identifier
      t.string :supplier_signer_identifier, index: true
      t.string :retailer_signer_identifier, index: true
      t.string :sign_status

      t.string :product_ids, array: true, default: []
      t.string :variant_ids, array: true, default: []
      t.timestamp :supplier_signed_at
      t.timestamp :retailer_signed_at
      t.timestamps
    end
  end
end
