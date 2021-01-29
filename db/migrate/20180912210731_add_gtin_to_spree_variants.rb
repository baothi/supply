class AddGtinToSpreeVariants < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_variants, :gtin, :string
    add_index :spree_variants, :gtin
  end
end
