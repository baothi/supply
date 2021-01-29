class AddDscoIdentifierToProductAndVariant < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_products, :dsco_identifier, :string
    add_column :spree_variants, :dsco_identifier, :string

    add_index :spree_products, :dsco_identifier
    add_index :spree_variants, :dsco_identifier
  end
end
