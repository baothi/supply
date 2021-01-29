class MigrateRetailConnectionIdsToOrders < ActiveRecord::Migration[6.0]
  def up
    begin
      Spree::Order.reset_column_information
      Spree::Order.find_each do |order|
        retail_connection = order.retail_connection

        retailer = retail_connection.retailer
        supplier = retail_connection.supplier
        order.update!(
            retailer_id: retailer.id,
            supplier_id: supplier.id
        )
      end
    rescue => e
      puts "Error copying retailer ids & supplier ids: #{e.message}".red
    end
  end

  def down
    Spree::Order.update_all(
        retailer_id: nil,
        supplier_id: nil
    )
  end
end
