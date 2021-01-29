class AddSourceToOrder < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_orders, :source, :string
  end
end
