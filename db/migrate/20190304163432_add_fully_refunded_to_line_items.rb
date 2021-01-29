class AddFullyRefundedToLineItems < ActiveRecord::Migration[6.0]
  def change
    # Subtotal refers to line item's variant cost * quantity
    unless column_exists?(:spree_line_items, :refunded_subtotal_at, :datetime)
      add_column :spree_line_items, :refunded_subtotal_at, :datetime
    end

    unless column_exists?(:spree_line_items, :refunded_shipping_at, :datetime)
      add_column :spree_line_items, :refunded_shipping_at, :datetime
    end

    unless column_exists?(:spree_line_items, :refunded_subtotal_at, :datetime)
      add_column :spree_line_items, :refunded_subtotal_at, :datetime
    end

    unless column_exists?(:spree_line_items, :refunded_tax_at, :datetime)
      add_column :spree_line_items, :refunded_tax_at, :datetime
    end

    unless column_exists?(:spree_line_items, :refunded_total_at, :datetime)
      add_column :spree_line_items, :refunded_total_at, :datetime
    end
  end
end
