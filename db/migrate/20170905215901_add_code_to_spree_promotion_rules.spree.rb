# This migration comes from spree (originally 20130903183026)
class AddCodeToSpreePromotionRules < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_promotion_rules, :code, :string
  end
end
