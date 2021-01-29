class AddLastGeneratedSupplierColorsForSuppliersAt < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_suppliers, :last_updated_colors_at, :datetime
  end
end
