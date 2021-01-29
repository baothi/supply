class CreateAdminUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :admin_users do |t|
      t.string :name
      t.string :email
      t.string :uid
      t.string :provider
      t.string :encrypted_password
      t.timestamps
    end
  end
end
