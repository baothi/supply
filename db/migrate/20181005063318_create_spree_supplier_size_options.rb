class CreateSpreeSupplierSizeOptions < ActiveRecord::Migration[6.0]
  def change
    create_table :spree_supplier_size_options do |t|
      t.integer :supplier_id, null: false, index: true
      t.string :name, null: false, index: true
      t.string :presentation
      t.integer :position, default: 0
      t.string :internal_identifier, null: false, index: true
      t.timestamps
    end
  end
end
