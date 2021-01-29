class AddStripeEmailToCustomer < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_retailers, :current_stripe_customer_email, :string
    add_column :spree_suppliers, :current_stripe_customer_email, :string
  end
end
