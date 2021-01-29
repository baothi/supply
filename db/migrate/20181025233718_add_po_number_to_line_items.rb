class AddPoNumberToLineItems < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_line_items, :purchase_order_number, :string
  end
end
