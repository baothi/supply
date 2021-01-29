class AddWeightUnitToVariants < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_variants, :weight_unit, :string
  end
end
