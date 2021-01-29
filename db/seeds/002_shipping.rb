### US Only ###
us_only = Spree::Zone.find_or_create_by!(
  name: 'United States',
  kind: 'country'
) do |zone|
  zone.description = 'United States Only'
end

%w(US).each do |name|
  us_only.zone_members.create!(zoneable: Spree::Country.find_by!(iso: name))
end
################

### Canada Only ###
canada = Spree::Zone.find_or_create_by!(
  name: 'Canada',
  kind: 'country'
) do |zone|
  zone.description = 'Canada Only'
end

%w(CA).each do |name|
  canada.zone_members.create!(zoneable: Spree::Country.find_by!(iso: name))
end
#########################

### Rest of the World ###
world_zone = Spree::Zone.find_or_create_by!(name: 'Rest of World') do |zone|
  zone.description = 'Rest of the world excluding US & Canada'
end

excluded_countries = %w(US CA)
Spree::Country.find_each do |country|
  world_zone.zone_members.create!(zoneable: country) unless
      excluded_countries.include?(country.iso)
end
#########################
