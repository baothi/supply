# FactoryBot.define do
#   factory :spree_webhook, class: 'Spree::Webhook' do
#     supplier factory: :spree_supplier
#     address Faker::Internet.url
#     topic do
#       %w(products/create products/update products/delete orders/create
#          collections/create collections/update collections/delete).sample
#     end
#     shopify_identifier { rand(10000..999999) }
#   end
# end
