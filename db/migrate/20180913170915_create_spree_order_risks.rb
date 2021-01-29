class CreateSpreeOrderRisks < ActiveRecord::Migration[6.0]
  def change
    create_table :spree_order_risks do |t|
      t.string :shopify_identifier
      t.boolean :cause_cancel
      t.boolean :display
      t.string :shopify_order_id
      t.string :message
      t.string :recommendation
      t.decimal :score
      t.string :source
      t.references :order, foreign_key: { to_table: 'spree_orders' }

      t.timestamps
    end
  end
end
