class AddNameAndPhoneNumberToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_users, :first_name, :string
    add_column :spree_users, :last_name, :string
    add_column :spree_users, :phone_number, :string
  end
end
