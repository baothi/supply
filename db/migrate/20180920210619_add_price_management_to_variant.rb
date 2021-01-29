class AddPriceManagementToVariant < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_variants, :price_management, :string, default: 'shopify'
  end
end
