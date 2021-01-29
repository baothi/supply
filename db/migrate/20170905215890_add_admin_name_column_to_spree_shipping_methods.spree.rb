# This migration comes from spree (originally 20130809164245)
class AddAdminNameColumnToSpreeShippingMethods < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_shipping_methods, :admin_name, :string
  end
end
