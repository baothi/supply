# This migration comes from spree (originally 20130626232741)
class AddCvvResultCodeAndCvvResultMessageToSpreePayments < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_payments, :cvv_response_code, :string
    add_column :spree_payments, :cvv_response_message, :string
  end
end
