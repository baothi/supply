FactoryBot.define do
  factory :spree_retailer_referral, class: 'Spree::RetailerReferral' do
    name { 'MyString' }
    string { 'MyString' }
    url { 'MyString' }
    email { 'MyString' }
    image_url { 'MyString' }
    has_relationship { false }
    spree_supplier { nil }
  end
end
