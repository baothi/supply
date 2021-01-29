class CreateSpreePlatformColorOptions < ActiveRecord::Migration[6.0]
  def change
    create_table :spree_platform_color_options do |t|
      t.string :name, null: false, index: true # Typically will be parametrized
      t.string :presentation
      # The ID of the row of the parent e.g. the ID of Red if this represents
      # Blood Red
      t.integer :parent_id
      t.string :hex_code # e.g. #0000000 - convention will be to store without the #
      t.integer :position, default: 0
      t.string :internal_identifier, null: false, index: true
      t.timestamps
    end
  end
end
