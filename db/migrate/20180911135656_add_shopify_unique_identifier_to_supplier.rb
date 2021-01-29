class AddShopifyUniqueIdentifierToSupplier < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_suppliers, :shopify_product_unique_identifier, :string, default: 'sku'
    add_column :spree_suppliers, :brand_short_code, :string

    update_legacy
  end

  def update_legacy
    begin
      suppliers = Spree::Supplier.where(shopify_product_unique_identifier: [nil, ''])
      suppliers.update_all(shopify_product_unique_identifier: 'sku')
    rescue => ex
      puts "#{ex}".red
    end
  end
end
