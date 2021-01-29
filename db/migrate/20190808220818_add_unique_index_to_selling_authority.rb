class AddUniqueIndexToSellingAuthority < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    add_index :spree_selling_authorities, [:retailer_id, :permittable_id, :permittable_type], unique: true, algorithm: :concurrently, name: 'index_spree_selling_authorities_on_retailer_and_permittable'
  end
end
