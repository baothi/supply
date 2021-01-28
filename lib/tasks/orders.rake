require 'spree'

namespace :orders do
  desc 'Update Searchable attribute for legacy orders'
  task update_searchable_attributes_for_orders: :environment do
    Spree::Order.find_each do |o|
      begin
        o.set_searchable_attributes
      rescue => e
        puts e.to_s.red
      end
    end
    puts 'Done updating searchable attributes'.green
  end

  desc 'Set highest order risk on legacy orders'
  task set_highest_order_risk_on_order: :environment do
    Spree::Order.find_each do |order|
      begin
        order.update(risk_recommendation: get_highest_risk_recommendation(order))
      rescue => e
        puts "Error!! #{e}".red
      end
    end

    puts 'All done!'
  end

  desc 'Set compliance dates'
  task set_compliance_dates_on_fulfilled_orders: :environment do
    begin
      Spree::Order.fulfilled.each(&:set_compliance_dates)
    rescue => e
      puts e.to_s.red
    end
    puts 'Done setting compliance dates on fulfilled orders.'.green
  end
  task set_compliance_dates_on_unfulfilled_orders: :environment do
    begin
      Spree::Order.unfulfilled.each(&:set_compliance_dates)
    rescue => e
      puts e.to_s.red
    end
    puts 'Done setting compliance dates on unnfulfilled orders.'.green
  end

  def get_highest_risk_recommendation(order)
    return 'cancel' if order.order_risks.any? { |r| r.recommendation == 'cancel' }
    return 'investigate' if order.order_risks.any? { |r| r.recommendation == 'investigate' }
    return 'accept' if order.order_risks.any? { |r| r.recommendation == 'accept' }

    ''
  end
end
