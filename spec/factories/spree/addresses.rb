FactoryBot.define do
  factory :spree_address, class: 'Spree::Address' do
    firstname { Faker::Name.first_name }
    lastname { Faker::Name.last_name }
    business_name { Faker::Company.name }
    address1 { Faker::Address.street_address }
    city { Faker::Address.city }
    zipcode { Faker::Address.zip_code.to_s.slice(0, 5) }
    phone { Faker::PhoneNumber.cell_phone }
    name_of_state { Faker::Address.state }
    state { |address| address.association(:spree_state) || Spree::State.last }
    country do |address|
      if address.state
        address.state.country
      else
        address.association(:spree_country)
      end
    end

    factory :us_spree_address do
      country factory: :country_usa
      # state do |address|
      #   address.country.states.first
      # end
    end

    factory :nigerian_spree_address do
      country factory: :country_nigeria
    end

    factory :canadian_spree_address do
      country factory: :country_canada
    end
  end
end
