class AddUsingTemporaryPasswordFlagToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_users, :using_temporary_password, :boolean, default: false
  end
end
