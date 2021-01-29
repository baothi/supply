class CreateSpreeOrderInvoices < ActiveRecord::Migration[6.0]
  def change
    create_table :spree_order_invoices do |t|
      t.string :number
      t.string :status
      t.decimal :amount, precision: 8, scale: 2, null: false
      t.references :order
      t.references :retail_connection
      t.timestamps
    end
  end
end
