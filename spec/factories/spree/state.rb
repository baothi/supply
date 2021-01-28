FactoryBot.define do
  factory :spree_state, class: 'Spree::State' do
    sequence(:name) { |_n| "STATE_NAME_#{rand(9999)}" }
    sequence(:abbr) { |_n| "STATE_ABBR_#{rand(9999)}" }
    country do |country|
      if usa = Spree::Country.find_by_numcode(840)
        usa
      else
        country.association(:spree_country)
      end
    end
  end
end
