# FactoryBot.define do
#   factory :shopify_webhook, class: Hash do
#     transient do
#     end

#     initialize_with do
#       webhook = Hashie::Mash.new
#       webhook.id = rand(100000)
#       webhook.topic = %w( products/create products/update products/delete orders/create
#                           collections/create collections/update collections/delete).sample
#       webhook.address = Faker::Internet.url
#       webhook.format = 'json'

#       webhook
#     end
#   end
# end
