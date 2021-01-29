class AddStateAbbreviationToUsAddress < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_addresses, :state_abbr, :string
  end
end
