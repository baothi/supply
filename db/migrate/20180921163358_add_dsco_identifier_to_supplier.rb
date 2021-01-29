class AddDscoIdentifierToSupplier < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_suppliers, :dsco_identifier, :string
  end
end
