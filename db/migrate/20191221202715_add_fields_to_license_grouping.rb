class AddFieldsToLicenseGrouping < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_groupings, :mini_identifier, :string
    add_column :spree_groupings, :slug, :string
    add_column :spree_groupings, :display_name, :string

    #  Add Indices
    add_index :spree_groupings, :mini_identifier, unique: true
    add_index :spree_groupings, :slug, unique: true
  end
end
