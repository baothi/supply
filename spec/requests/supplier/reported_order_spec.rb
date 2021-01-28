require 'rails_helper'

RSpec.describe 'Reported Order', type: :request do
  before do
    # @supplier = create(:spree_supplier)
    sign_in(spree_supplier.users.first)
  end

  describe 'GET /supplier/orders/reported' do
    it 'renders the index view' do
      get 'http://localhost:3000/supplier/orders/reported'
      expect(response).to render_template(:reported)
    end
  end

  describe 'POST /supplier/orders/reported' do
    before do
      # @order = create(:spree_order_with_line_items, supplier: spree_supplier)
      @order_issue = create(:spree_order_issue_report)
      @order = @order_issue.order
      @order.update(supplier_id: spree_supplier.id)
    end

    context 'when approving issue' do
      it 'sets amount credited' do
        post 'http://localhost:3000/supplier/orders/reported',
             params: {
               commit: 'Approve',
               ammount: 10,
               order_id: @order.internal_identifier
             }

        expect(flash[:notice]).to include 'Resolved'
      end
    end

    context 'when approving issue' do
      it 'sets amount credited' do
        post 'http://localhost:3000/supplier/orders/reported',
             params: {
               commit: 'Decline',
               reason: 'bad report',
               order_id: @order.internal_identifier
             }

        expect(flash[:notice]).to include 'Resolved'
      end
    end
  end
end
