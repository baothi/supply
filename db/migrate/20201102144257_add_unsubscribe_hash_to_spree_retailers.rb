class AddUnsubscribeHashToSpreeRetailers < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_retailers, :unsubscribe_hash, :string
    add_column :spree_retailers, :unsubscribe, :text, array: true, default: []
  end
end
