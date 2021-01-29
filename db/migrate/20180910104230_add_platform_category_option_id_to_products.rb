class AddPlatformCategoryOptionIdToProducts < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_products, :supplier_category_option_id, :integer
    add_column :spree_products, :platform_category_option_id, :integer
  end
end
