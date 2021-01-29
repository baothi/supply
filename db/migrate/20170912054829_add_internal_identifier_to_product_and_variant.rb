class AddInternalIdentifierToProductAndVariant < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_products, :internal_identifier, :string
    add_column :spree_variants, :internal_identifier, :string
    add_index :spree_products, :internal_identifier
    add_index :spree_variants, :internal_identifier
  end
end
