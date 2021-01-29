class CreateSpreeOrderIssueReports < ActiveRecord::Migration[6.0]
  def change
    create_table :spree_order_issue_reports do |t|
      t.references :order, foreign_key: { to_table: 'spree_orders' }
      t.text :description
      t.string :resolution
      t.text :decline_reason
      t.decimal :amount_credited
      t.attachment :image1
      t.attachment :image2

      t.timestamps
    end
  end
end
