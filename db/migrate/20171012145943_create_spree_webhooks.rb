class CreateSpreeWebhooks < ActiveRecord::Migration[6.0]
  def change
    create_table :spree_webhooks do |t|
      t.string  :address
      t.string  :topic
      t.string  :shopify_identifier
      t.integer :teamable_id
      t.string  :teamable_type
      t.timestamps
    end
    add_index :spree_webhooks, [:teamable_type, :teamable_id]
  end
end
