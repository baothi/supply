class MigrationOrderInvoicesAwayFromRetailConnection < ActiveRecord::Migration[6.0]
  def up
    add_column :spree_order_invoices, :retailer_id, :integer, index: true
    add_column :spree_order_invoices, :supplier_id, :integer, index: true
    Spree::OrderInvoice.reset_column_information
    Spree::OrderInvoice.find_each do |order_invoice|
      begin
        order = order_invoice.order

        retailer = order.retailer
        supplier = order.supplier
        order_invoice.update!(
            retailer_id: retailer.id,
            supplier_id: supplier.id
        )
      rescue => e
        puts "MigrationOrderInvoicesAwayFromRetailConnection: "\
        "Error copying retailer ids & supplier ids: #{e.message}".red
      end
    end
    remove_column(:spree_order_invoices, :retail_connection_id, :integer)
  end

  def down
    remove_column(:spree_order_invoices, :retailer_id, :integer)
    remove_column(:spree_order_invoices, :supplier_id, :integer)
    add_column :spree_order_invoices, :retail_connection_id, :integer
  end

end
