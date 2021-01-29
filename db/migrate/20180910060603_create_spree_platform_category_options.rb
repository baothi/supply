class CreateSpreePlatformCategoryOptions < ActiveRecord::Migration[6.0]
  def change
    create_table :spree_platform_category_options do |t|
      t.string :name, null: false, index: true # Typically will be parametrized
      t.string :presentation
      t.integer :parent_id # The ID of the row of the parent e.g. the ID of Accessories
      t.integer :position, default: 0
      t.string :internal_identifier, null: false, index: true
      t.timestamps
    end
  end
end
