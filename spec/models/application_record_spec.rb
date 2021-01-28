require 'rails_helper'

RSpec.describe ApplicationRecord, type: :model do
  describe '.all_polymorphic_types' do
    context 'when tested with :permittable polymorphic association' do
      it 'includes Spree::Product in array response' do
        allow(ShopifyAPI::GraphQL).to receive(:new).and_return MockedGraphQLClient.new
        expect(ApplicationRecord.all_polymorphic_types(:permittable)).to be_an Array
        expect(ApplicationRecord.all_polymorphic_types(:permittable)).to include 'Spree::Product'
      end
    end

    context 'when tested with random non-existent polymorphic symbol' do
      it 'returns nil if nothing is found' do
        expect(ApplicationRecord.all_polymorphic_types(:non_existent_poly)).to be_nil
      end
    end
  end
end
