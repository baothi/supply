class AddBannersToLicenses < ActiveRecord::Migration[6.0]
  def change
    add_attachment :spree_taxons, :outer_banner
    add_attachment :spree_taxons, :inner_banner
  end
end
