class AddLogToProductExportProcess < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_product_export_processes, :log, :text
    add_column :spree_product_export_processes, :error_log, :text
  end
end
