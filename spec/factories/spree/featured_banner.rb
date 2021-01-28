FactoryBot.define do
  factory :spree_featured_banner, class: 'Spree::FeaturedBanner' do
    title { Faker::Lorem.word }
    description { Faker::Lorem.sentence }
    taxon factory: :spree_taxon
  end
end
