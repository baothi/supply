class AddProcessingStatusToOrder < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_orders, :shopify_processing_status, :string
  end
end
