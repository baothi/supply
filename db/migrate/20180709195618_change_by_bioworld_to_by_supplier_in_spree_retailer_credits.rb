class ChangeByBioworldToBySupplierInSpreeRetailerCredits < ActiveRecord::Migration[6.0]
  def change
    rename_column :spree_retailer_credits, :by_bioworld, :by_supplier
  end
end
