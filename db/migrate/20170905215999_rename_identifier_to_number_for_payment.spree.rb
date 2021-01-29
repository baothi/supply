# This migration comes from spree (originally 20141218025915)
class RenameIdentifierToNumberForPayment < ActiveRecord::Migration[6.0]
  def change
    rename_column :spree_payments, :identifier, :number
  end
end
