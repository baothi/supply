class CreateSpreeSellingAuthorities < ActiveRecord::Migration[6.0]
  def change
    create_table :spree_selling_authorities do |t|
      t.references :retailer, foreign_key: { to_table: 'spree_retailers' }
      t.references :permittable, polymorphic: true, index: { name: 'index_on_permittable_type_id' }
      t.integer :permission

      t.timestamps
    end
  end
end
