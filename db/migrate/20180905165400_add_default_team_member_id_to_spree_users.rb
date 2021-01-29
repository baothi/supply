class AddDefaultTeamMemberIdToSpreeUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_users, :default_team_member_id, :integer
  end
end
