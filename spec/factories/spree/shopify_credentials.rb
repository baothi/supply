FactoryBot.define do
  factory :spree_shopify_credential, class: Spree::ShopifyCredential do
    teamable factory: :spree_retailer
    access_token { Faker::Internet.password(min_length: 15) }
    store_url { Faker::Internet.slug }
  end
end
