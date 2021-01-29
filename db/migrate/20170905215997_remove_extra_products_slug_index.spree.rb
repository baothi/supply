# This migration comes from spree (originally 20141215235502)
class RemoveExtraProductsSlugIndex < ActiveRecord::Migration[6.0]
  def change
    remove_index :spree_products, name: :permalink_idx_unique
  end
end
