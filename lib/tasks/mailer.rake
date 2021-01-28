require 'spree'

namespace :mailer do
  desc 'email retailers for unpaid orders'
  task unpaid_orders_notifier: :environment do
    retailers = Spree::Retailer.has_remindable_unpaid_orders
    retailers.find_each do |retailer|
      UserMailer.unpaid_orders(retailer).deliver_later
      puts "Emailed #{retailer.name}".green
    end

    puts "All done. All #{retailers.size} retailers emailed".green
  end

  desc 'email retailers of auto-paid order'
  task auto_paid_orders_notifier: :environment do
    Spree::Order.auto_paid_not_notified.group_by(&:retailer_id).each do |retailer_id, orders|
      OrdersMailer.auto_paid_orders(retailer_id, orders.pluck(:id)).deliver_later
      puts "Processed orders for retailer #{retailer_id}"
    end

    puts 'All done!!'
  end
end
