class AddSentViaEdiAtToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_orders, :sent_via_edi_at, :datetime
  end
end
