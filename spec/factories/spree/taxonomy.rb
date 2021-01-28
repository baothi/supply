FactoryBot.define do
  factory :spree_taxonomy, class: Spree::Taxonomy do
    sequence(:name) { |n| "taxonomy_#{n}" }
  end
end
