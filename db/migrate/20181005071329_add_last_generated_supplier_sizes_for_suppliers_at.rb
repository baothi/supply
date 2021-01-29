class AddLastGeneratedSupplierSizesForSuppliersAt < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_suppliers, :last_updated_sizes_at, :datetime

  end
end
