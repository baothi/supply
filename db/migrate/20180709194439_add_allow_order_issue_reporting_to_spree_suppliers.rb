class AddAllowOrderIssueReportingToSpreeSuppliers < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_suppliers, :allow_order_issue_reporting, :boolean, default: true
  end
end
