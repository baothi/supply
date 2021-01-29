class AddAppNameToRetailers < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_retailers, :app_name, :string
  end
end
