# This migration comes from spree (originally 20141002191113)
class AddCodeToSpreeShippingMethods < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_shipping_methods, :code, :string
  end
end
