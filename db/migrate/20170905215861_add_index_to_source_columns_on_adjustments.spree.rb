# This migration comes from spree (originally 20130417120034)
class AddIndexToSourceColumnsOnAdjustments < ActiveRecord::Migration[6.0]
  def change
    add_index :spree_adjustments, [:source_type, :source_id]
  end
end