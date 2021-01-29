class AddPaymentReminderCountToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_orders, :payment_reminder_count, :integer, default: 0
  end
end
