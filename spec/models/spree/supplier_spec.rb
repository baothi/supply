require 'rails_helper'

RSpec.describe Spree::Supplier, type: :model do
  subject { build(:spree_supplier) }

  it_behaves_like 'an internal_identifiable model'
  it_behaves_like 'a sluggable model', :spree_retailer

  describe 'Model from Factory' do
    it { is_expected.to be_valid }
    it { expect(subject.name).to be_a String }

    context 'when any of the required fields is nil' do
      it { expect(build(:spree_supplier, name: nil)).not_to be_valid }
      it { expect(build(:spree_supplier, email: nil)).not_to be_valid }
    end
  end

  describe 'Active model validation' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:email) }
  end

  describe 'Active model associations' do
    it { is_expected.to have_many(:team_members) }
    it { is_expected.to have_many(:users).through(:team_members) }
    it { is_expected.to have_one(:stripe_customer) }
    it { is_expected.to have_one(:shopify_credential) }

    it do
      expect(subject).to have_many(:selling_authorities).dependent(:destroy)
    end

    it do
      expect(subject).to have_many(:permit_selling_authorities).conditions(permission: :permit).
        class_name('Spree::SellingAuthority')
    end

    it do
      expect(subject).to have_many(:reject_selling_authorities).conditions(permission: :reject).
        class_name('Spree::SellingAuthority')
    end

    it do
      expect(subject).to have_many(:white_listed_retailers).through(:permit_selling_authorities).
        source(:retailer)
    end

    it do
      expect(subject).to have_many(:black_listed_retailers).through(:reject_selling_authorities).
        source(:retailer)
    end
  end

  describe 'scopes' do
    before do
      @suppliers = create_list(:spree_supplier, 5)
    end

    describe '.has_permit_selling_authority' do
      context 'when NO supplier has permit authority' do
        before do
          Spree::SellingAuthority.destroy_all
        end

        it 'returns an empty array' do
          expect(Spree::Supplier.has_permit_selling_authority).to be_an ActiveRecord::Relation
          expect(Spree::Supplier.has_permit_selling_authority).to be_empty
        end
      end

      context 'when permit selling authority is set on some suppliers' do
        let(:supplier1) { @suppliers.first }
        let(:supplier2) { @suppliers.second }
        let(:supplier3) { @suppliers.third }

        before do
          create :permit_selling_authority, permittable: supplier1
          create :permit_selling_authority, permittable: supplier2
        end

        it 'does NOT return empty array' do
          expect(Spree::Supplier.has_permit_selling_authority).not_to be_empty
        end

        it 'contains supplier1 and supplier2' do
          expect(Spree::Supplier.has_permit_selling_authority).to include supplier1
          expect(Spree::Supplier.has_permit_selling_authority).to include supplier2
        end

        it 'does NOT include supplier3' do
          expect(Spree::Supplier.has_permit_selling_authority).not_to include supplier3
        end
      end
    end

    describe '.has_reject_selling_authority' do
      context 'when NO Supplier has permit authority' do
        before do
          Spree::SellingAuthority.destroy_all
        end

        it 'returns an empty array' do
          expect(Spree::Supplier.has_reject_selling_authority).to be_an ActiveRecord::Relation
          expect(Spree::Supplier.has_reject_selling_authority).to be_empty
        end
      end

      context 'when permit selling authority is set on some suppliers' do
        let(:supplier1) { @suppliers.first }
        let(:supplier2) { @suppliers.second }
        let(:supplier3) { @suppliers.third }

        before do
          create :reject_selling_authority, permittable: supplier1
          create :reject_selling_authority, permittable: supplier2
        end

        it 'does NOT return empty array' do
          expect(Spree::Supplier.has_reject_selling_authority).not_to be_empty
        end

        it 'contains supplier1 and supplier2' do
          expect(Spree::Supplier.has_reject_selling_authority).to include supplier1
          expect(Spree::Supplier.has_reject_selling_authority).to include supplier2
        end

        it 'does NOT include supplier3' do
          expect(Spree::Supplier.has_reject_selling_authority).not_to include supplier3
        end
      end
    end
  end

  describe 'callbacks' do
    context '#send_welcome_email' do
      let(:mailer) { double('SupplierMailer', deliver_later: true) }

      it 'schedules welcome email' do
        expect(SupplierMailer).to receive(:welcome).with(Integer).and_return(mailer)

        create(:spree_supplier)
      end

      it 'schedules invite retailers email' do
        expect(SupplierMailer).to receive(:invite_retailers).with(Integer).and_return(mailer)

        create(:spree_supplier)
      end
    end
  end
end
