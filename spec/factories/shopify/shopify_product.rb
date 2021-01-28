# FactoryBot.define do
#   factory :shopify_product, class: Hash do
#     transient do
#     end

#     initialize_with do
#       product = Hashie::Mash.new
#       product.id = rand(100000)
#       product.title = "Shopify Product ##{rand(100000)}"
#       product.options = Hashie::Mash.new
#       product.variants = Hashie::Mash.new
#       product.body_html = nil

#       product.variants = build_list(:shopify_variant, 10)
#       product.price_range = '$20 - $50' # Random

#       product
#     end
#   end
# end
