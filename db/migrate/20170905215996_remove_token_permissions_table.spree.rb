# This migration comes from spree (originally 20141215232040)
class RemoveTokenPermissionsTable < ActiveRecord::Migration[6.0]
  def change
    # The MoveOrderTokenFromTokenizedPermission migration never dropped this.
    drop_table :spree_tokenized_permissions
  end
end
