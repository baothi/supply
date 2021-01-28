Spree::Address.class_eval do
  before_validation :set_country_to_us,
                    :set_state_to_not_in_use

  def set_country_to_us
    self.country = Spree::Country.find_by(iso: 'US') unless self.country.present?
  end

  def country_name
    country&.name
  end

  # Overwrite the default
  def require_zipcode?
    false
  end

  def set_state_to_not_in_use
    self.state = country.states.find_by(name: 'NOT_IN_USE')
  end

  def self.find_state_abbreviation(full_name)
    return '' if full_name.blank?

    results = Spree::State.
              joins(:country).
              where('spree_states.name = :state_full_name and spree_countries.iso = :country_iso',
                    state_full_name: full_name,
                    country_iso: 'US')
    results.first&.abbr
  end

  def eligible_for_state_abbreviation_usage?
    return true if self.state_abbr.blank? && us_address? && name_of_state.present?

    false
  end

  def build_state_abbreviation
    self.state_abbr = Spree::Address.find_state_abbreviation(self.name_of_state)
  end

  def set_state_abbreviation!
    build_state_abbreviation
    self.save!
  end

  def set_unknown_names
    self.first_name = 'N/A'
    self.last_name = 'N/A'
  end

  def transfer_from_shop_owner(shop_owner)
    return if shop_owner.blank?

    shop_owner = shop_owner.split(' ')
    self.first_name = shop_owner[0]
    self.last_name = shop_owner[1]
  end

  def country_iso
    self.country.iso unless self.country.nil?
  end

  def us_address?
    self.country&.iso == 'US'
  end

  # For now, only works with US-addresses
  def state_abbreviation; end
end
