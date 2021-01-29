class CreateSpreeProductExportProcesses < ActiveRecord::Migration[6.0]
  def change
    create_table :spree_product_export_processes do |t|
      t.references :product
      t.references :retailer
      t.string :status

      t.timestamps
    end
  end
end
