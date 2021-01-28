FactoryBot.define do
  factory :spree_woo_credential do
    store_url { "MyString" }
    consumer_key { "MyString" }
    consumer_secret { "MyString" }
    teamable_type { "MyString" }
    teamable_id { 1 }
    uninstalled_at { "2021-01-04 15:04:52" }
  end
end
