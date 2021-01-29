class AddFullyRefundedToOrders < ActiveRecord::Migration[6.0]
  def change
    unless column_exists?(:spree_orders, :fully_refunded_subtotal_at, :datetime)
      add_column :spree_orders, :fully_refunded_subtotal_at, :datetime
    end

    unless column_exists?(:spree_orders, :fully_refunded_shipping_at, :datetime)
      add_column :spree_orders, :fully_refunded_shipping_at, :datetime
    end

    unless column_exists?(:spree_orders, :fully_refunded_subtotal_at, :datetime)
      add_column :spree_orders, :fully_refunded_subtotal_at, :datetime
    end

    unless column_exists?(:spree_orders, :fully_refunded_tax_at, :datetime)
      add_column :spree_orders, :fully_refunded_tax_at, :datetime
    end

    unless column_exists?(:spree_orders, :fully_refunded_total_at, :datetime)
      add_column :spree_orders, :fully_refunded_total_at, :datetime
    end
  end
end
