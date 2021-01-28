FactoryBot.define do
  factory :spree_role, class: 'Spree::Role' do
    name { Faker::Internet.user_name }
  end
end
