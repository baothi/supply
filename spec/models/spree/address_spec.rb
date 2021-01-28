require 'rails_helper'

RSpec.describe Spree::Address, type: :model do
  subject { build :spree_address }

  let(:nigerian_address) do
    build(:nigerian_spree_address)
  end

  let(:us_address) do
    build(:us_spree_address)
  end

  describe 'Model from Factory' do
    it { is_expected.to be_valid }

    context 'when any of the required fields is nil' do
      it { expect(build(:spree_address, first_name: nil)).not_to be_valid }
      it { expect(build(:spree_address, address1: nil)).not_to be_valid }
    end
  end

  describe 'Model collbacks' do
    it { is_expected.to callback(:set_country_to_us).before(:validation) }
    it { is_expected.to callback(:set_state_to_not_in_use).before(:validation) }
    # it { is_expected.to callback(:build_state_abbreviation).before(:validation) }

    describe 'after validation' do
      before { us_address.validate! }

      context 'for US addresses' do
        it { expect(us_address.country.iso).to eql 'US' }
        it { expect(us_address.state.name).to eql 'NOT_IN_USE' }
      end

      context 'for non-US addresses or empty addresses' do
        before do
          nigerian_address.validate!
        end

        it { expect(nigerian_address.country.iso).to eql 'NG' }
        it { expect(nigerian_address.state.name).to eql 'NOT_IN_USE' }
        it { expect(nigerian_address.state_abbr).to be_blank }
      end
    end
  end

  describe '#eligible_for_state_abbreviation_usage?' do
    it 'returns true when the right conditions are met' do
      us_address = build(:us_spree_address, state_abbr: '', name_of_state: 'Pennsylvania')
      expect(us_address).
        to be_eligible_for_state_abbreviation_usage
    end

    it 'returns false when any of right conditions are not met' do
      us_address = build(:us_spree_address, state_abbr: 'PA', name_of_state: 'Pennsylvania')
      expect(us_address).
        not_to be_eligible_for_state_abbreviation_usage
    end
  end

  # describe '#build_state_abbreviation' do
  #   it 'works as expected for US orders' do
  #     allow(Spree::Address).to receive(:find_state_abbreviation).and_return('NV')
  #     addr = build(:us_spree_address, state_abbr: '', name_of_state: 'Nevada')
  #     addr.validate!
  #
  #     expect(addr.state_abbr).to eq 'NV'
  #   end
  #
  #   it 'sets abbreviation to blank for non-US orders' do
  #     allow(Spree::Address).to receive(:find_state_abbreviation).and_return(nil)
  #     addr = build(:nigerian_spree_address, state_abbr: '', name_of_state: 'Lekki Beach')
  #     addr.validate!
  #
  #     expect(addr.state_abbr).to be_blank
  #   end
  # end
end
