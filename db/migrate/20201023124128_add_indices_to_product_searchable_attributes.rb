class AddIndicesToProductSearchableAttributes < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def change
    add_index :spree_products, :search_attributes,
              name:'spree_products_search_attr_gin_idx',
              using: :gin,
              algorithm: :concurrently
    add_index :spree_products, "(search_attributes->'license_taxons') jsonb_path_ops",
              name:'spree_products_search_attr_license_taxons_gin_idx',
              using: :gin,
              algorithm: :concurrently
    add_index :spree_products, "(search_attributes->'category_taxons') jsonb_path_ops",
              name:'spree_products_search_attr_category_taxons_gin_idx',
              using: :gin,
              algorithm: :concurrently
  end
end
