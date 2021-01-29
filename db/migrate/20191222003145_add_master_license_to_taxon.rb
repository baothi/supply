class AddMasterLicenseToTaxon < ActiveRecord::Migration[6.0]
  def change
    # Add some more toggles
    add_column :spree_taxons, :master_license, :boolean
    add_column :spree_taxons, :master_category, :boolean
    add_column :spree_taxons, :visible, :boolean
    # Supplier & Retailer
    add_column :spree_taxons, :supplier_id, :integer
    add_column :spree_taxons, :retailer_id, :integer
  end
end
