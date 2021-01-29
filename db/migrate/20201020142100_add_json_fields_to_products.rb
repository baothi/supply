class AddJsonFieldsToProducts < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_products, :search_attributes, :jsonb, null: false, default: {}
    add_column :spree_products, :search_attributes_updated_at, :datetime


  end
end
