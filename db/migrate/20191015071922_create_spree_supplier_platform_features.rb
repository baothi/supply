class CreateSpreeSupplierPlatformFeatures < ActiveRecord::Migration[6.0]
  def change
    create_table :spree_supplier_platform_features do |t|
      t.string :plan_name, unique: true
      t.string :stripe_plan_identifier
      t.jsonb :settings, null: false, default: {}
      t.boolean :active
      t.datetime :expire_at
      t.timestamps
    end
  end
end
