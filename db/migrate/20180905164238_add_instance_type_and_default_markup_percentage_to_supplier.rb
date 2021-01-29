class AddInstanceTypeAndDefaultMarkupPercentageToSupplier < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_suppliers, :instance_type, :string
    add_column :spree_suppliers, :default_markup_percentage, :float
  end
end
