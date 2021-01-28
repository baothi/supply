require 'rails_helper'

RSpec.describe 'Retailer Order Batch Action', type: :request do
  before do
    sign_in(spree_retailer.users.first)

    allow(Spree::Retailer).to(
      receive(:locate_by_host).and_return(spree_retailer)
    )
  end

  describe 'POST /retailer/batch_action' do
    context 'archive orders' do
      it 'archives selected orders' do
        orders = create_list(
          :spree_completed_order_with_totals,
          5,
          retailer: spree_retailer
        )
        upate_order_retailer_id(orders, spree_retailer.id)
        order = orders.sample
        post 'http://localhost:3000/retailer/orders/batch-action',
             params: { order_ids: [order.internal_identifier], batch_action: 'Archive Orders' }

        order.reload
        expect(order.archived_at).not_to be nil
      end
    end
  end
end

def upate_order_retailer_id(orders,  retailer_id)
  Spree::Order.where(id: orders.pluck(:id)).
    update_all(retailer_id: retailer_id)
end
