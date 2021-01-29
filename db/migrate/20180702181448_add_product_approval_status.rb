class AddProductApprovalStatus < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_products, :submission_state, :string
  end
end
