class AddSupplierIdToStockLocation < ActiveRecord::Migration[6.0]
  def change
    add_reference :spree_stock_locations, :supplier
  end
end
