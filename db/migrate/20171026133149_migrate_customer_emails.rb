class MigrateCustomerEmails < ActiveRecord::Migration[6.0]

  def up
    begin
      Spree::Order.reset_column_information
      Spree::Order.find_each do |order|
        email = order.email
        next if email.nil?

        order.update!(
            customer_email: email
        )
      end
    rescue => e
      puts "Error copying customer email #{e.message}".red
    end
  end

  def down
    puts 'Skipping MigrateCustomerEmails'.yellow
  end
end
