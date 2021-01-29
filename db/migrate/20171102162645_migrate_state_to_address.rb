class MigrateStateToAddress < ActiveRecord::Migration[6.0]
  def up
    begin
      Spree::Address.reset_column_information
      Spree::Address.find_each do |address|
        address.name_of_state = address.state_text
        address.save!
      end
    rescue => e
      puts "Error copying address email #{e.message}".red
    end
  end

  def down
  end
end
