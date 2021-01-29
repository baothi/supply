class ChangeSellerAuthoritiesPermissionToString < ActiveRecord::Migration[6.0]
  def change
    change_column :spree_selling_authorities, :permission, :string
  end
end
