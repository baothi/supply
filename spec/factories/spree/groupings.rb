FactoryBot.define do
  factory :spree_grouping, class: 'Spree::Grouping' do
    name { Faker::Lorem.word }
    group_type { Spree::Grouping.group_types.keys.sample }
  end
end
