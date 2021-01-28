Spree::Zone.class_eval do
  has_many :shipping_zone_eligibilities, dependent: :destroy
  has_many :suppliers_that_ship, through: :shipping_zone_eligibilities,
                                 class_name: 'Spree::Supplier'

  def self.usa
    Spree::Zone.find_by(name: 'United States')
  end

  def self.canada
    Spree::Zone.find_by(name: 'Canada')
  end

  def self.rest_of_world
    Spree::Zone.find_by(name: 'Rest of World')
  end
end
