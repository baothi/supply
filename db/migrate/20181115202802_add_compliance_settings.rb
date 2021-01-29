class AddComplianceSettings < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_orders, :must_acknowledge_by, :datetime
    add_column :spree_orders, :must_fulfill_by, :datetime
    add_column :spree_orders, :must_cancel_by, :datetime
    add_column :spree_orders, :will_incur_penalty_at, :datetime
  end
end
