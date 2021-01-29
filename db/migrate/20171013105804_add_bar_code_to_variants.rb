class AddBarCodeToVariants < ActiveRecord::Migration[6.0]
  def change
    # We add both just for sake of protecting future
    add_column :spree_variants, :barcode, :string
    add_column :spree_variants, :upc, :string
    add_index :spree_variants, :barcode
    add_index :spree_variants, :upc
  end
end
