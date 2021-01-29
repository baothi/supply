class CreateSpreeRefundRecords < ActiveRecord::Migration[6.0]
  def up
    unless (table_exists? :spree_refund_records)
      create_table :spree_refund_records do |t|
        t.references :refund, foreign_key: { to_table: 'spree_refunds' }
        # Legacy - means this refund existing before we launched this feature.
        t.string :refund_type   # tax, shipping, line_item, order, blended, legacy
        t.string :log # Log for keeping track of reason
        t.boolean :is_partial
        t.timestamps
      end
    end
  end

  def down
    drop_table(:spree_refund_records, if_exists: true)
  end
end
