class CreateGroupings < ActiveRecord::Migration[6.0]
  def change
    create_table :spree_groupings do |t|
      t.string :internal_identifier, index: true
      t.string :name
      t.text :description
      t.string :group_type

      t.timestamps
    end
  end
end
