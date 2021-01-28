FactoryBot.define do
  factory :supply_admin_user, class: AdminUser do
    email { 'xxx@hingeto.com' }
    uid { '1111111' }
    provider { 'google_oauth2' }
  end
end
