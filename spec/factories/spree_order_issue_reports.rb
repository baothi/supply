FactoryBot.define do
  factory :spree_order_issue_report, class: 'Spree::OrderIssueReport' do
    order factory: :spree_order
    description { Faker::Lorem.paragraph }
  end
end
