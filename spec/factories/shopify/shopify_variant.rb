# FactoryBot.define do
#   factory :shopify_variant, class: Hash do
#     transient do
#     end

#     initialize_with do
#       variant = Hashie::Mash.new
#       variant.id = rand(100000)
#       variant.title = "Shopify Variant / #{variant.id}"
#       variant.sku = "Random SKU #{variant.id}"
#       variant.inventory_quantity = rand(100)
#       variant.price = rand(5.0...200.5).round(2)
#       variant.option1 = 'option1 : Pink'
#       variant.option2 = 'option2 : L'
#       variant
#     end
#   end
# end
