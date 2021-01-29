class CreateSpreeSupplierLicenseOptions < ActiveRecord::Migration[6.0]
  def change
    create_table :spree_supplier_license_options do |t|
      t.integer :supplier_id, null: false, index: true
      t.string :name, null: false, index: true
      t.string :presentation
      t.integer :position, default: 0
      t.string :internal_identifier, null: false, index: true
      t.datetime :last_updated_licenses_at
      t.timestamps
    end
  end
end
