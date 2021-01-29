class AddInternalIdentifiableToOrder < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_orders, :internal_identifier, :string
    add_index :spree_orders, :internal_identifier
  end
end
