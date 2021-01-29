class RenameVersionsTable < ActiveRecord::Migration[6.0]
  def change
    rename_table :versions, :variant_cost_versions
  end
end
