# This migration comes from spree (originally 20130514151929)
class AddSkuIndexToSpreeVariants < ActiveRecord::Migration[6.0]
  def change
    add_index :spree_variants, :sku
  end
end