FactoryBot.define do
  factory :spree_country, class: 'Spree::Country' do
    sequence(:iso_name) { |_n| "ISO_NAME_#{rand(9999)}" }
    sequence(:name) { |_n| "NAME_#{rand(9999)}" }
    iso { 'US' }
    iso3 { 'USA' }
    numcode { 840 }

    factory :spree_country_with_states do
      after(:create) do |country|
        create :spree_state, name: 'NOT_IN_USE', abbr: 'NOT_IN_USE', country: country
        create_list :spree_state, 2, country: country
      end
    end

    factory :country_nigeria do
      before(:create) do |country|
        country.iso_name = 'NIGERIA'
        country.name = 'Nigeria'
        country.iso  = 'NG'
        country.iso3 = 'NGA'
        country.zipcode_required = false
      end

      after(:create) do |country|
        create :spree_state, name: 'NOT_IN_USE', abbr: 'NOT_IN_USE', country: country
        create_list :spree_state, 2, country: country
      end
    end

    factory :country_usa do
      before(:create) do |country|
        country.iso_name = 'UNITED STATES'
        country.name = 'United States'
        country.iso = 'US'
        country.iso3 = 'USA'
      end

      after(:create) do |country|
        create :spree_state, name: 'NOT_IN_USE', abbr: 'NOT_IN_USE', country: country
        create_list :spree_state, 2, country: country
      end
    end

    factory :country_canada do
      iso_name { 'CANADA' }
      name { 'Canada' }
      iso { 'CA' }
      iso3 { 'CAN' }
      zipcode_required { false }

      # after(:create) do |country|
      #   create :spree_state, name: 'NOT_IN_USE', abbr: 'NOT_IN_USE', country: country
      #   create_list :spree_state, 2, country: country
      # end
    end
  end
end
