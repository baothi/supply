class AddPlatformOptionIdToSupplierCategoryOption < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_supplier_category_options, :platform_category_option_id, :integer
  end
end
