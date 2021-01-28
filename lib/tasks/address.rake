require 'spree'

namespace :address do
  desc 'Update business name in retailer shipping and legal addresses'
  task update_retailer_addresses_business_name: :environment do
    Spree::Retailer.find_each do |r|
      r.shipping_address.update(business_name: r.name) if r.shipping_address
      r.legal_entity_address.update(business_name: r.name) if r.legal_entity_address

      puts "Updated shipping and business address for #{r.name}".green
    end

    puts 'Done updating addresses'.green
  end
end
