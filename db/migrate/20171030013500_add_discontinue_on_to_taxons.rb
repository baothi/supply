class AddDiscontinueOnToTaxons < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_taxonomies, :discontinue_on, :datetime
    add_column :spree_taxons, :discontinue_on, :datetime
    add_column :spree_taxonomies, :deleted_at, :datetime
    add_column :spree_taxons, :deleted_at, :datetime
  end
end
