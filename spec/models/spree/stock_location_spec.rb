require 'rails_helper'

RSpec.describe Spree::StockLocation, type: :model do
  subject { build :spree_stock_location }

  describe '#set_backorderable_default' do
    it 'sets backorderable_default to true'  do
      subject.save!
      expect(subject.backorderable_default).to be true
    end
  end
end
