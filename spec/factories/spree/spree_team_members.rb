FactoryBot.define do
  factory :spree_team_member, class: 'Spree::TeamMember' do
    teamable factory: :spree_retailer
    user factory: :spree_user

    transient do
      role_name { 'test_admin' }
    end

    role do
      Spree::Role.find_by(name: role_name) || FactoryBot.create(:spree_role, name: role_name)
    end
  end
end
