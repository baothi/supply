FactoryBot.define do
  factory :spree_retailer_inventory, class: 'Spree::RetailerInventory' do
    retailer factory: :spree_retailer
    inventory do
      {
          "#{Faker::Code.ean}": 100
      }
    end
  end
end
