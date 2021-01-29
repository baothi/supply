class AddRetailCOnnectionToOrder < ActiveRecord::Migration[6.0]
  def change
    add_reference :spree_orders, :retail_connection
  end
end
