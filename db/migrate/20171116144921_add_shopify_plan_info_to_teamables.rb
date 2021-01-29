class AddShopifyPlanInfoToTeamables < ActiveRecord::Migration[6.0]
  def change
    # Retailer
    add_column :spree_retailers, :domain, :string
    add_column :spree_retailers, :plan_name, :string
    add_column :spree_retailers, :plan_display_name, :string

    # Supplier
    add_column :spree_suppliers, :domain, :string
    add_column :spree_suppliers, :plan_name, :string
    add_column :spree_suppliers, :plan_display_name, :string
  end
end
