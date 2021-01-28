module Spree::RetailersAndSuppliers::Teamable
  extend ActiveSupport::Concern

  def team_type
    self.class.name.split('Spree::')[1].downcase
  end
end
