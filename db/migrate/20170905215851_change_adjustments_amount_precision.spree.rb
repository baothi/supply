# This migration comes from spree (originally 20130319082943)
class ChangeAdjustmentsAmountPrecision < ActiveRecord::Migration[6.0]
  def change

    change_column :spree_adjustments, :amount,  :decimal, precision: 10, scale: 2

  end
end
