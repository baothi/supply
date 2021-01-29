class AddGoogleCategoryIdAndGoogleCategoryNestedStringToSpreeTaxons < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_taxons, :google_category_id, :integer
    add_column :spree_taxons, :google_category_nested_string, :string

    add_index :spree_taxons, :google_category_id
    add_index :spree_taxons, :google_category_nested_string
  end
end
