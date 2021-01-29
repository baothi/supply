class AddSoldForPriceToLineItems < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_line_items, :sold_at_price, :decimal, precision: 8, scale: 2, default: 0
  end
end
