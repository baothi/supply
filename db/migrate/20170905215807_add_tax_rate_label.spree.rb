# This migration comes from spree (originally 20120905145253)
class AddTaxRateLabel < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_tax_rates, :name, :string
  end
end
