class AddSupplierRetailerToLineItem < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_line_items, :retailer_id, :integer, index: true
    add_column :spree_line_items, :supplier_id, :integer, index: true
  end
end
