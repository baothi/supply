class AddFieldsToTaxons < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_taxons, :mini_identifier, :string
    add_column :spree_taxons, :slug, :string
    add_column :spree_taxons, :display_name, :string

    #  Add Indices
    add_index :spree_taxons, :mini_identifier, unique: true
    add_index :spree_taxons, :slug, unique: true
  end
end
