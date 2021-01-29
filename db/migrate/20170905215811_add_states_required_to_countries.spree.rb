# This migration comes from spree (originally 20121010142909)
class AddStatesRequiredToCountries < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_countries, :states_required, :boolean, default: true
  end
end
