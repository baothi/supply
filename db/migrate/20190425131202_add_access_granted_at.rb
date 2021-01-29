class AddAccessGrantedAt < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_retailers, :access_granted_at, :datetime
    add_column :spree_suppliers, :access_granted_at, :datetime
  end
end
