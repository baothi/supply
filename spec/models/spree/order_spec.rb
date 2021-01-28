require 'rails_helper'

RSpec.describe Spree::Order, type: :model do
  subject { build :spree_order }

  let(:nigerian_address) do
    build(:nigerian_spree_address)
  end
  let(:retailer) { create :spree_retailer }

  before do
    Spree::Order.destroy_all
  end

  it_behaves_like 'an internal_identifiable model'

  describe 'Active Record Association' do
    it { is_expected.to have_one(:order_issue_report).dependent(:destroy) }
    it { is_expected.to have_one(:retailer_credit).through(:retailer) }
  end

  describe '#before_validate' do
    it 'generates a sample order before saving'  do
      subject.source = 'app'
      subject.save!
      expect(subject.number).to include 'SAMPLE'
    end

    it 'ensures two orders do not have same order number for the same retailer' do
      retailer = create :spree_retailer
      order1 = create :spree_order, source: 'app', retailer: retailer
      order2 = create :spree_order, source: 'app', retailer: retailer
      expect(order1.number).to include 'SAMPLE'
      expect(order2.number).to include 'SAMPLE'
      expect(order1.number).not_to eq order2.number
    end

    it 'ensures two orders do not have same order number for different retailers' do
      retailer1 = create :spree_retailer
      retailer2 = create :spree_retailer
      order1 = create :spree_order, source: 'app', retailer: retailer1
      order2 = create :spree_order, source: 'app', retailer: retailer2
      expect(order1.number).to include 'SAMPLE'
      expect(order2.number).to include 'SAMPLE'
      expect(order1.number).not_to eq order2.number
    end

    it 'does not include SAMPLE in order number for non-samples' do
      subject.source = nil
      subject.save!
      expect(subject.number).not_to include 'SAMPLE'
    end
  end

  describe 'scopes' do
    context '.sample_orders_with_free_shipping' do
      it 'returns retailer orders with free shipping' do
        sample_orders_with_free_shipping = create_list(
          :spree_order_ready_to_ship,
          3,
          source: 'app'
        )
        create_list(
          :spree_order_ready_to_ship,
          4,
          source: 'app',
          total_shipment_cost: 5
        )
        expect(
          Spree::Order.sample_orders_with_free_shipping.count
        ).to eq sample_orders_with_free_shipping.count
      end
    end

    context '.international' do
      describe 'for international retailer orders' do
        it 'returns international retailer orders' do
          @order_a, @order_b, @order_c = create_list(:spree_order, 3, source: '')
          @order_a.ship_address = nigerian_address
          @order_a.save
          expect(Spree::Order.international.count).to eq 1
        end
      end

      describe 'returns international retailer orders' do
        it 'returns only international retailer orders' do
          @order_a, @order_b, @order_c = create_list(:spree_order, 3, source: '')
          @order_a.ship_address = nigerian_address
          @order_a.save
          @order_b.ship_address = nigerian_address
          @order_b.save
          @order_c.ship_address = nigerian_address
          @order_c.save
          create_list(:spree_order, 2, source: '')
          expect(Spree::Order.international.count).to eq 3
        end
      end
    end

    context '.non_sample_orders' do
      it 'returns retailer orders with free shipping' do
        create_list(:spree_order_ready_to_ship, 5, source: 'app')
        non_sample_orders = create_list(
          :spree_order_ready_to_ship,
          4,
          total_shipment_cost: 5
        )
        expect(Spree::Order.non_sample_orders.sort).to eq non_sample_orders.sort
      end
    end

    context '.retailer_name' do
      before do
        @retailer = create :spree_retailer, name: 'Test Retailer Store'
        @order = create :spree_order, retailer: @retailer
      end

      it 'returns the retailer name linked to the order' do
        expect(@order.retailer_name).to eql 'Test Retailer Store'
      end
    end

    context '.supplier_name' do
      before do
        @supplier = create :spree_supplier, name: 'Test Supplier Store'
        @order = create :spree_order, supplier: @supplier
      end

      it 'returns the suppliers name linked to the order' do
        expect(@order.supplier_name).to eql 'Test Supplier Store'
      end
    end

    context '.filter_by_attributes' do
      before do
        @orders = create_list(:spree_order_ready_to_ship, 5)
        @orders.map(&:set_searchable_attributes)
      end

      it 'returns only orders mathcing passed param' do
        order = @orders.first
        expect(Spree::Order.filter_by_attributes(order.number)).to include order
      end
      it 'returns only orders mathcing passed param' do
        order = @orders.first
        expect(Spree::Order.filter_by_attributes(order.number)).not_to include @orders.last
      end
    end

    context '.filter_by_status' do
      it 'filters paid orders when paid param is passed' do
        expect(Spree::Order).to receive(:paid)
        Spree::Order.filter_by_status('paid')
      end
      it 'filters unpaid orders when unpaid param is passed' do
        expect(Spree::Order).to receive(:unpaid)
        Spree::Order.filter_by_status('unpaid')
      end
      it 'filters fulfilled orders when fulfilled param is passed' do
        expect(Spree::Order).to receive(:fulfilled)
        Spree::Order.filter_by_status('fulfilled')
      end
      it 'filters unfulfilled orders when unfulfilled param is passed' do
        expect(Spree::Order).to receive(:unfulfilled)
        Spree::Order.filter_by_status('unfulfilled')
      end
      it 'filters international orders when international param is passed' do
        expect(Spree::Order).to receive(:international)
        Spree::Order.filter_by_status('international')
      end
    end

    describe '.stripe_id' do
      before do
        @order1, @order2, @order3 = create_list(:spree_order, 3, completed_at: Time.now)
        @payment1 = create(:payment, order: @order1, number: 'Test-1')
        @payment2 = create(:payment, order: @order2, number: 'Test-2')
        @payment3 = create(:payment, order: @order3, number: 'Test-3')
      end

      it 'returns the order of the specified stripe id' do
        expect(Spree::Order.stripe_id('Test-1').size).to be 1
        expect(Spree::Order.stripe_id('Test-1')).to include @order1
        expect(Spree::Order.stripe_id('Test-1')).not_to include @order2
        expect(Spree::Order.stripe_id('Test-1')).not_to include @order3
      end

      it 'returns the orders that partially match the specified stripe id' do
        expect(Spree::Order.stripe_id('Test').size).to be 3
        expect(Spree::Order.stripe_id('Test')).to include @order1
        expect(Spree::Order.stripe_id('Test')).to include @order2
        expect(Spree::Order.stripe_id('Test')).to include @order3
      end
    end

    describe '.remindable_unpaid_orders' do
      before do
        @order1, @order2, @order3, @order4 = create_list(:spree_order, 4, completed_at: Time.now)
        create(:payment, order: @order1) # order with payment
        @order2.update(payment_reminder_count: 3) # Exhusted reminder count
      end

      it 'returns an activerecord relation of 2 orders' do
        expect(Spree::Order.remindable_unpaid_orders).to be_a Spree::Order::ActiveRecord_Relation
        expect(Spree::Order.remindable_unpaid_orders.size).to be 2
      end

      it 'contains @order3 and @order4 but not @order1 and @order2' do
        expect(Spree::Order.remindable_unpaid_orders).to include @order3
        expect(Spree::Order.remindable_unpaid_orders).to include @order4
        expect(Spree::Order.remindable_unpaid_orders).not_to include @order1
        expect(Spree::Order.remindable_unpaid_orders).not_to include @order2
      end
    end

    describe '.is_reported' do
      before do
        @order1, @order2, @order3, @order4 = create_list(:spree_order, 4)
        create(:spree_order_issue_report, order: @order1)
        create(:spree_order_issue_report, order: @order2)
      end

      it 'returns 2 orders' do
        expect(Spree::Order.is_reported.size).to be 2
      end

      it 'includes @order3 and @order4' do
        expect(Spree::Order.is_reported).to include @order1
        expect(Spree::Order.is_reported).to include @order2
      end

      it 'does NOT include @order1 and @order2' do
        expect(Spree::Order.is_reported).not_to include @order3
        expect(Spree::Order.is_reported).not_to include @order4
      end
    end
  end

  describe '.sample_orders_for_this_month' do
    it 'returns sample orders with free shipping within current month' do
      orders = create_list(:spree_order, 5,
                           source: 'app',
                           completed_at: DateTime.now,
                           total_shipment_cost: 0)
      orders.first.update(completed_at: orders.first.completed_at + 2.month)
      expect(Spree::Order.sample_orders_for_this_month.count).to eq 4
    end
  end

  describe '#paid?' do
    it 'returns false if payment association does NOT exists' do
      expect(subject.paid?).to be false
    end

    it 'returns true if payment association exists' do
      subject.save
      create(:payment, order: subject)
      expect(subject.paid?).to be true
    end
  end

  describe '#total_discount' do
    context 'when no discount is used' do
      it 'returns 0.0' do
        expect(subject.total_discount).to eq 0.0
      end
    end

    context 'when supplier and/or hingeto discount is available' do
      before do
        subject.supplier_discount = 30.0
        subject.hingeto_discount = 20.0
      end

      it 'returns sum of 30.0 and 20.0' do
        expect(subject.total_discount).to eq 50.0
      end
    end
  end

  describe 'price_after_discount' do
    subject do
      build :spree_order_with_line_items
    end

    before do
      subject.supplier_discount = 5.0
      subject.hingeto_discount = 5.0
    end

    it 'returns the difference between grand_total and total discount' do
      expect(subject.price_after_discount).to be < subject.grand_total
      expect(subject.price_after_discount).to eq subject.grand_total - 10.0
    end
  end

  describe 'apply_credit_discount!' do
    context 'when retailer has credit' do
      subject { create :spree_order_with_line_items }

      before do
        create(:spree_retailer_credit, retailer: subject.retailer)
        subject.apply_credit_discount!
      end

      it 'sets supplier_discount' do
        expect(subject.supplier_discount).not_to be_zero
      end

      it 'the price after discount is less than or equal to grand total' do
        expect(subject.price_after_discount).to be <= subject.grand_total
        expect(subject.price_after_discount).to eq subject.grand_total - subject.total_discount
      end
    end

    context 'when retailer has no credit' do
      before do
        subject.apply_credit_discount!
      end

      it 'remains 0 for supplier_discount' do
        expect(subject.supplier_discount).to be_zero
      end
    end
  end

  describe '#attempt_start_auto_payment!' do
    def setup_stripe_cards_for_retailer(retailer)
      # Has Stripe Cards
      StripeService.create_stripe_customer(retailer)
      StripeService.add_card_to_customer(
        retailer.stripe_customer, stripe_helper.generate_card_token
      )
    end

    before do
      ActiveJob::Base.queue_adapter = :test
      StripeMock.start
    end

    let(:spree_retailer) do
      create :spree_retailer,
             order_auto_payment: true
    end

    after { StripeMock.stop }

    it 'does not auto pay for risky orders' do
      order = build :spree_order,
                    retailer: spree_retailer

      setup_stripe_cards_for_retailer(spree_retailer)

      allow(order).to receive(:risky?).and_return(true)
      allow(order).to receive(:grand_total).and_return(50)

      expect do
        order.save
        order.attempt_start_auto_payment!
      end.not_to have_enqueued_job(Shopify::OrderExportJob)
    end

    it 'does not auto pay for expensive orders' do
      order = build :spree_order,
                    retailer: spree_retailer
      setup_stripe_cards_for_retailer(spree_retailer)

      allow(order).to receive(:risky?).and_return(false)
      allow(order).to receive(:grand_total).and_return(300)

      expect do
        order.save
        order.attempt_start_auto_payment!
      end.not_to have_enqueued_job(Shopify::OrderExportJob)
    end

    it 'does not auto pay when auto pay is not enabled' do
      order = build :spree_order,
                    retailer: spree_retailer

      setup_stripe_cards_for_retailer(spree_retailer)

      spree_retailer.order_auto_payment = false
      spree_retailer.save

      allow(order).to receive(:risky?).and_return(false)
      allow(order).to receive(:grand_total).and_return(50)

      expect do
        order.save
        order.attempt_start_auto_payment!
      end.not_to have_enqueued_job(Shopify::OrderExportJob)
    end

    it 'creates jobs and enqueue background worker correctly' do
      order = build :spree_order,
                    retailer: spree_retailer

      setup_stripe_cards_for_retailer(spree_retailer)

      expect do
        order.save
        order.attempt_start_auto_payment!
      end.to have_enqueued_job(Shopify::OrderExportJob)
    end
  end

  describe '#retailer_default_shipping_method_id' do
    it 'can handle US orders properly' do
      spree_retailer.default_us_shipping_method_id = 4
      spree_retailer.save

      current_order = create :spree_order,
                             retailer: spree_retailer

      allow(current_order).to receive(:us_order?).and_return true

      expect(current_order.retailer_default_shipping_method_id).to eq 4
    end

    it 'can handle Canada orders properly' do
      spree_retailer.default_canada_shipping_method_id = 5
      spree_retailer.save

      current_order = create :spree_order,
                             retailer: spree_retailer

      allow(current_order).to receive(:us_order?).and_return false
      allow(current_order).to receive(:canada_order?).and_return true

      expect(current_order.retailer_default_shipping_method_id).to eq 5
    end
  end

  context 'transitions for order remittance' do
    describe 'full remittance' do
      it 'transitions the full cycle as expected' do
        current_order = create :spree_order, retailer: spree_retailer

        expect(current_order).to transition_from(:scheduled).
          to(:country_check).on_event(:check_country)
        expect(current_order).to transition_from(:country_check).
          to(:cost_check).on_event(:check_costs)
        expect(current_order).to transition_from(:cost_check).
          to(:quantity_check).on_event(:check_quantity)
        expect(current_order).to transition_from(:quantity_check).
          to(:payment_remittance).on_event(:remit_payment)
        expect(current_order).to transition_from(:payment_remittance).
          to(:order_remittance).on_event(:remit_order)
        expect(current_order).to transition_from(:order_remittance).
          to(:successfully_sent_order).on_event(:complete_remittance)
      end
    end
  end

  describe '#passed_fulfillment_date?' do
    context 'when the order has no must_fulfill_by date' do
      it 'returns false' do
        expect(subject).not_to be_passed_fulfillment_date
      end
    end

    context 'when the order has must_fulfill_by date' do
      it 'returns true if the must_fulfill_by date is in the past' do
        order = build(:spree_order, must_fulfill_by: 3.business_days.ago)

        expect(order).to be_passed_fulfillment_date
      end

      it 'returns false if the must_fulfill_by date is in the future' do
        order = build(:spree_order, must_fulfill_by: 3.business_days.from_now)

        expect(order).not_to be_passed_fulfillment_date
      end
    end
  end

  describe '#days_to_ship' do
    context 'when the order has no must_fulfill_by date' do
      it 'returns N/A' do
        expect(subject.days_to_ship).to eq 'N/A'
      end
    end

    context 'when the order is not piad' do
      it 'returns N/A' do
        subject.must_fulfill_by = 3.business_days.from_now
        subject.save!

        expect(subject.days_to_ship).to eq 'N/A'
      end
    end

    context "when the order has passed it's fulfillment date" do
      it 'returns the numbers of business days between the fufillment date and today' do
        order = create(:spree_order)
        order.update(must_fulfill_by: 3.business_days.ago)
        create(:payment, order: order)

        fulfillment_date = order.must_fulfill_by.to_date
        days = fulfillment_date.business_days_until(DateTime.now) * -1

        expect(order.days_to_ship).to eq days
      end
    end

    context "when the order has not reached it's fulfillment date" do
      it 'ensures the returned date does not exceed 3 business days' do
        order = create(:spree_order)
        order.update(must_fulfill_by: 30.business_days.from_now)
        create(:payment, order: order)

        expect(order.days_to_ship).not_to be > 3
      end
    end
  end
end
