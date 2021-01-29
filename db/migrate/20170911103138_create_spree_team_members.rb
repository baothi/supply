class CreateSpreeTeamMembers < ActiveRecord::Migration[6.0]
  def change
    create_table :spree_team_members do |t|
      t.references :teamable, polymorphic: true
      t.references :user, foreign_key: { to_table: :spree_users }
      t.references :role, foreign_key: { to_table: :spree_roles }
      t.string :internal_identifier
      t.timestamps
    end
  end
end
