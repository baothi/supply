class CreateSpreeMappedShippingMethods < ActiveRecord::Migration[6.0]
  def change
    create_table :spree_mapped_shipping_methods do |t|
      t.string :teamable_type
      t.integer :teamable_id
      t.references :shipping_method
      t.string :value # The team's corresponding value
      t.timestamps
    end
    add_index :spree_mapped_shipping_methods, [:teamable_type, :teamable_id],
              :name => 'index_on_teamable_for_mapped_shipping_methods'

    add_index :spree_mapped_shipping_methods, [:teamable_type, :teamable_id, :shipping_method_id],
              :name => 'index_on_teamable_and_method_on_mapped_shipping_methods',
              :unique => true
  end
end
