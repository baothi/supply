class AddMapPriceToVariants < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_variants, :map_price, :decimal
  end
end
