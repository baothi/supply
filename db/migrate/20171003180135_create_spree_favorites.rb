class CreateSpreeFavorites < ActiveRecord::Migration[6.0]
  def change
    create_table :spree_favorites do |t|
      t.references :retailer
      t.references :product
      t.timestamps
    end
  end
end
