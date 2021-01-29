# This is a hack because the other seeds are good about first_or_create! The zones one is not.
# Hence seeding can't be easily re-run without complaining about unique zones

if Spree::Zone.all.empty?
  Spree::Core::Engine.load_seed if defined?(Spree::Core)
end

Spree::Auth::Engine.load_seed if defined?(Spree::Auth) && !Supply::ReviewApp::Helpers.review_app?

OTHER_ROLES = %w(admin).freeze

Spree::Supplier::ROLES.each do |role|
  Spree::Role.find_or_create_by(name: role)
end

Spree::Retailer::ROLES.each do |role|
  Spree::Role.find_or_create_by(name: role)
end

OTHER_ROLES.each do |role|
  Spree::Role.find_or_create_by(name: role)
end

# Since we do not use Spree's infrastructure, we create a
# fake state to use for all addresses
Spree::Country.all.each do |country|
  Spree::State.find_or_create_by(
    name: 'NOT_IN_USE',
    abbr: 'NOT_IN_USE',
    country: country
  )
end
