class CreateSpreePlatformSizeOptions < ActiveRecord::Migration[6.0]
  def change
    create_table :spree_platform_size_options do |t|
      # Typically will be parametrized and a combination of name_1 & name_2
      t.string :name, null: false, index: true
      # a combination of name_1 & description_2
      t.string :presentation
      t.string :name_1, null: false, index: true
      t.string :name_2
      # In the event we have triplexl and 3XL and want to specify that they're the same
      t.integer :parent_id
      t.integer :position, default: 0
      t.string :internal_identifier, null: false, index: true
      t.timestamps
    end
  end
end
