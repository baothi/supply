class AddLineItemNumberToLineItems < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_line_items, :line_item_number, :string
  end
end
