class AddImageCounterToProduct < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_products, :image_counter, :integer, default: 0
    add_column :spree_products, :last_updated_image_counter_at, :datetime
  end
end
