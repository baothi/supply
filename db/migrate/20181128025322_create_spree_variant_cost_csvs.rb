class CreateSpreeVariantCostCsvs < ActiveRecord::Migration[6.0]
  def change
    create_view :spree_variant_cost_csvs
  end
end
