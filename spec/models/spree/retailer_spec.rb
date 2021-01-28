require 'rails_helper'

RSpec.describe Spree::Retailer, type: :model do
  subject { build(:spree_retailer) }

  before { ActiveJob::Base.queue_adapter = :test }

  before do
    Mongoid.purge!
  end

  it_behaves_like 'an internal_identifiable model'
  it_behaves_like 'a sluggable model', :spree_retailer
  it_behaves_like 'a follower model'

  describe 'Model from Factory' do
    it { is_expected.to be_valid }
    it { expect(subject.name).to be_a String }

    context 'when any of the required fields is nil' do
      it { expect(build(:spree_retailer, name: nil)).not_to be_valid }
      it { expect(build(:spree_retailer, email: nil)).not_to be_valid }
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
    it { is_expected.to have_one(:retailer_credit).dependent(:destroy) }
    it { is_expected.to have_one(:retailer_inventory) }
    it { is_expected.to belong_to(:legal_entity_address) }
    it { is_expected.to belong_to(:shipping_address) }

    it { is_expected.to accept_nested_attributes_for(:legal_entity_address) }
    it { is_expected.to accept_nested_attributes_for(:shipping_address) }

    it { is_expected.to have_many(:selling_authorities).dependent(:destroy) }

    it do
      expect(subject).to have_many(:permit_selling_authorities).conditions(permission: :permit).
        class_name('Spree::SellingAuthority')
    end

    it do
      expect(subject).to have_many(:reject_selling_authorities).conditions(permission: :reject).
        class_name('Spree::SellingAuthority')
    end

    it do
      expect(subject).to have_many(:white_listed_products).through(:permit_selling_authorities).
        source(:permittable)
    end

    it do
      expect(subject).to have_many(:black_listed_products).through(:reject_selling_authorities).
        source(:permittable)
    end

    it do
      expect(subject).to have_many(:white_listed_suppliers).through(:permit_selling_authorities).
        source(:permittable)
    end

    it do
      expect(subject).to have_many(:black_listed_suppliers).through(:reject_selling_authorities).
        source(:permittable)
    end
  end

  describe 'Delegated methods' do
    it { is_expected.to delegate_method(:has_credit?).to(:retailer_credit) }
    it { is_expected.to delegate_method(:total_available_credit).to(:retailer_credit) }
  end

  describe 'Scopes' do
    describe '.has_remindable_unpaid_orders' do
      before do
        @retailer1 = create(:spree_retailer) # Retailer with paid order
        order = create(:spree_order, retailer: @retailer1, completed_at: Time.now)
        create(:payment, order: order) # payment for order

        @retailer2 = create(:spree_retailer) # Retailer with order that has exhusted reminder count
        create(
          :spree_order, retailer: @retailer2, completed_at: Time.now, payment_reminder_count: 3
        )

        @retailer3 = create(:spree_retailer) # Retailer with completed order but not paid for it
        create(:spree_order, retailer: @retailer3, completed_at: Time.now)
      end

      it 'returns activerecord relation of 1 retailer' do
        expect(Spree::Retailer.has_remindable_unpaid_orders).
          to be_a Spree::Retailer::ActiveRecord_Relation

        expect(Spree::Retailer.has_remindable_unpaid_orders.size).to be 1
      end

      it 'includes retailer3, but not retailer 1 and 2' do
        expect(Spree::Retailer.has_remindable_unpaid_orders).to include @retailer3
        expect(Spree::Retailer.has_remindable_unpaid_orders).not_to include @retailer1
        expect(Spree::Retailer.has_remindable_unpaid_orders).not_to include @retailer2
      end
    end
  end

  describe '.locate_by_host' do
    it 'return nils when no retailer is in the database' do
      Spree::Retailer.destroy_all
      expect(Spree::Retailer.locate_by_host('anything')).to be_nil
    end

    it 'returns the first retailer in DB if exist' do
      expect(Spree::Retailer.locate_by_host('anthing')).to eql Spree::Retailer.first
    end
  end

  describe '#add_team_member' do
    let(:role) { create(:spree_role) }

    before { subject.save }

    context 'when the user creation fails' do
      before do
        allow(Spree::User).to receive(:create).and_return(false)
      end

      let(:add_team_member_result) { subject.add_team_member(attributes_for(:spree_user), role.id) }

      it 'returns false when user is not created' do
        expect(add_team_member_result).to be_falsey
      end

      it "does not change the count of retailer's users" do
        expect { add_team_member_result }.not_to change { subject.users.count }
      end
    end

    context 'when the team member creation fails' do
      before do
        allow_any_instance_of(Spree::Retailer).to receive_message_chain(:team_members, :create).
          and_return(false)
      end

      let(:add_team_member_result) { subject.add_team_member(attributes_for(:spree_user), role.id) }

      it 'returns false trying to create team_member' do
        expect(add_team_member_result).to be_falsey
      end

      it "does not change the count of retailer's users" do
        expect { add_team_member_result }.not_to change { subject.users.count }
      end

      it 'receives the "team_members" message once' do
        # expect(subject).to receive(:team_members).once
      end
    end

    context 'when the user and team_member creation succeeds' do
      let(:add_team_member_result) { subject.add_team_member(attributes_for(:spree_user), role.id) }

      it 'returns does not return false' do
        expect(add_team_member_result).not_to be_falsey
      end

      it "does not change the count of retailer's users" do
        expect { add_team_member_result }.to change { subject.users.count }
      end
    end
  end

  describe '#following_licenses' do
    before do
      license_taxonomy = create(:taxonomy, name: 'License')
      create_list(:taxon, 4)
      create_list(:taxon, 3, taxonomy: license_taxonomy)
      @license_taxon1, @license_taxon2 = create_list(:taxon, 2, taxonomy: license_taxonomy)
      @other_taxon1, @other_taxon2 = create_list(:taxon, 2)
      spree_retailer.follow(@license_taxon1)
      spree_retailer.follow(@other_taxon1)
    end

    it 'returns only 1 taxon' do
      expect(spree_retailer.following_licenses.count).to be 1
    end

    it 'includes the followed "@license_taxon1" in the response' do
      expect(spree_retailer.following_licenses).to include @license_taxon1
    end

    it 'does NOT include the "@license_taxon2" which is not followed' do
      expect(spree_retailer.following_licenses).not_to include @license_taxon2
    end

    it 'does NOT include the "@other_taxon1" which is followed' do
      expect(spree_retailer.following_licenses).not_to include @other_taxon1
    end

    it 'does NOT include the "@license_taxon2" which is not followed' do
      expect(spree_retailer.following_licenses).not_to include @other_taxon2
    end
  end

  describe '#following_categories' do
    before do
      category_taxonomy = create(:taxonomy, name: 'Platform Category')
      create_list(:taxon, 4)
      create_list(:taxon, 3, taxonomy: category_taxonomy)
      @category_taxon1, @category_taxon2 = create_list(:taxon, 2, taxonomy: category_taxonomy)
      @other_taxon1, @other_taxon2 = create_list(:taxon, 2)
      spree_retailer.follow(@category_taxon1)
      spree_retailer.follow(@other_taxon1)
    end

    it 'returns only 1 taxon' do
      expect(spree_retailer.following_categories.count).to be 1
    end

    it 'includes the followed "@category_taxon1" in the response' do
      expect(spree_retailer.following_categories).to include @category_taxon1
    end

    it 'does NOT include the "@category_taxon2" which is not followed' do
      expect(spree_retailer.following_categories).not_to include @category_taxon2
    end

    it 'does NOT include the "@other_taxon1" which is followed' do
      expect(spree_retailer.following_categories).not_to include @other_taxon1
    end

    it 'does NOT include the "@category_taxon2" which is not followed' do
      expect(spree_retailer.following_categories).not_to include @other_taxon2
    end
  end

  describe '#default_address_model' do
    it 'returns a Spree::Address instance' do
      expect(subject.default_address_model).to be_a Spree::Address
    end

    it 'return Spree::Address instance with address attributes defined in Retailer' do
      address = subject.default_address_model

      expect(address.address1).to eql subject.address1
      expect(address.address2).to eql subject.address2
      expect(address.city).to eql subject.city
      expect(address.zipcode).to eql subject.zipcode
      expect(address.phone).to eql subject.phone
      expect(address.alternative_phone).to eql subject.phone_number
      expect(address.state_name).to eql subject.state
      expect(address.name_of_state).to eql subject.state
    end
  end

  describe '#all_blocked_product_ids' do
    let(:products) { create_list(:spree_product, 5) }
    let(:product1) { products.first }
    let(:product2) { products.second }
    let(:product3) { products.third }
    let(:product4) { products.fourth }

    before do
      subject.save
      create :reject_selling_authority, permittable: product1, retailer: subject
      create :permit_selling_authority, permittable: product2
      create :permit_selling_authority, permittable: product3, retailer: subject
    end

    it 'contains products blocked for subject' do
      expect(subject.all_blocked_product_ids).to include product1.internal_identifier
    end

    it 'contains products whitelisted for others' do
      expect(subject.all_blocked_product_ids).to include product2.internal_identifier
    end

    it 'does NOT contain products whitelisted for me' do
      expect(subject.all_blocked_product_ids).not_to include product3.internal_identifier
    end

    it 'does not contain products that are neither blacklisted nor whitelisted' do
      expect(subject.all_blocked_product_ids).not_to include product4.internal_identifier
    end
  end

  describe '#all_blocked_supplier_ids' do
    let(:suppliers) { create_list(:spree_supplier, 5) }
    let(:supplier1) { suppliers.first }
    let(:supplier2) { suppliers.second }
    let(:supplier3) { suppliers.third }
    let(:supplier4) { suppliers.fourth }

    before do
      subject.save
      create :reject_selling_authority, permittable: supplier1, retailer: subject
      create :permit_selling_authority, permittable: supplier2
      create :permit_selling_authority, permittable: supplier3, retailer: subject
    end

    it 'contains suppliers blocked for subject' do
      expect(subject.all_blocked_supplier_ids).to include supplier1.internal_identifier
    end

    it 'contains suppliers whitelisted for others' do
      expect(subject.all_blocked_supplier_ids).to include supplier2.internal_identifier
    end

    it 'does NOT contain suppliers whitelisted for me' do
      expect(subject.all_blocked_supplier_ids).not_to include supplier3.internal_identifier
    end

    it 'does not contain suppliers that are neither blacklisted nor whitelisted' do
      expect(subject.all_blocked_supplier_ids).not_to include supplier4.internal_identifier
    end
  end

  describe '#can_access_product?' do
    let(:products) { create_list(:spree_product, 5) }
    let(:product1) { products.first }
    let(:product2) { products.second }
    let(:product3) { products.third }
    let(:product4) { products.fourth }

    before do
      subject.save
      create :reject_selling_authority, permittable: product1, retailer: subject
      create :reject_selling_authority, permittable: product2.supplier, retailer: subject
      create :permit_selling_authority, permittable: product3, retailer: subject
    end

    it 'returns false for blocked product' do
      expect(subject).not_to be_can_access_product(product1)
    end

    it 'return false for product whose supplier is blocked' do
      expect(subject).not_to be_can_access_product(product2)
    end

    it 'returns true for permitted product' do
      expect(subject).to be_can_access_product(product3)
    end

    it 'returns true for neutral product' do
      expect(subject).to be_can_access_product(product4)
    end
  end

  describe '#generate_inventories!' do
    let(:supplier) { create(:spree_supplier) }
    let(:variant_listings) do
      create_list(:spree_variant_listing, 2, retailer: subject, supplier_id: supplier.id)
    end
    let(:skus) { variant_listings.map(&:variant).map(&:platform_supplier_sku) }
    let(:shopify_product) do
      create(:shopify_cache_product,
             shopify_url: subject.shopify_url,
             role: 'retailer',
             variants: [
                 FactoryBot.build(
                   :shopify_cache_product_variant,
                   sku: skus[0]
                 ),
                 FactoryBot.build(
                   :shopify_cache_product_variant,
                   sku: skus[1]
                 )
             ])
    end

    before { shopify_product.reload }

    it 'generates retailer inventory hash from cache' do
      subject.generate_inventories!
      inventory_record = subject.inventory_record
      hash = inventory_record.inventory

      expect(hash.keys).to match_array skus
    end
  end

  # Found in Listings Concern (listings.rb)
  describe 'Listings Concern' do
    describe '#products_ids_for_added_listings' do
      it 'returns the expected list of ids' do
        retailer = create(:spree_retailer)
        product_listings = create_list(:spree_product_listing,
                                       5,
                                       retailer_id: retailer.id,
                                       supplier_id: spree_supplier.id)
        ids = product_listings.pluck(:product_id)
        retailer_product_ids = retailer.products_ids_for_added_listings
        expect(retailer_product_ids).to match_array(ids)
      end
    end
  end

  describe 'callbacks' do
    # context '#send_welcome_email' do
    #   let(:mailer) { double('RetailerMailer', deliver_later: true) }
    #
    #   it 'schedules welcome email' do
    #     expect(RetailerMailer).to receive(:welcome).with(Integer).and_return(mailer)
    #
    #     create(:spree_retailer)
    #   end
    # end

    # context '#schedule_referral_email' do
    #   let(:mailer) { double('RetailerMailer', deliver_later: true) }
    #
    #   it 'schedules invite vendors email' do
    #     expect(RetailerMailer).to receive(:invite_vendors).with(Integer).and_return(mailer)
    #
    #     create(:spree_retailer)
    #   end
    # end
  end
end
