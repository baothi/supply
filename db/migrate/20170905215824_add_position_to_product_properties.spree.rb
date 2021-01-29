# This migration comes from spree (originally 20130120201805)
class AddPositionToProductProperties < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_product_properties, :position, :integer, default: 0
  end
end

