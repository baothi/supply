FactoryBot.define do
  factory :spree_supplier_referral, class: 'Spree::SupplierReferral' do
    name { 'MyString' }
    string { 'MyString' }
    url { 'MyString' }
    email { 'MyString' }
    image_url { 'MyString' }
    has_relationship { false }
    spree_retailer { nil }
  end
end
