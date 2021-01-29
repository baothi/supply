class AddPseudonymToSupplier < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_suppliers, :pseudonym, :string
  end
end
