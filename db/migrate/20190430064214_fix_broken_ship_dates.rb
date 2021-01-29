class FixBrokenShipDates < ActiveRecord::Migration[6.0]
  def change
    # This is used to copy over all of the invalid fulfilled at that was set up until
    # 4/29/2019.
    add_column :spree_line_items, :invalid_fulfilled_at, :datetime
    add_column :spree_shipments, :invalid_fulfilled_at, :datetime
  end
end
