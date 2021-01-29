class CreateSpreeStockItemTrackings < ActiveRecord::Migration[6.0]
  def change
    create_table :spree_stock_item_trackings do |t|
      t.references  :stock_item, foreign_key: { to_table: 'spree_stock_items' }
      t.references  :product, foreign_key: { to_table: 'spree_products' }
      t.string      :state

      t.timestamps
    end
  end
end
