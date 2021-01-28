require 'rails_helper'

RSpec.describe 'Replace Line Items Spec', type: :feature do
  let!(:retailer) do
    spree_retailer
  end

  let!(:current_user) do
    retailer.users.first
  end

  let!(:order) do
    create(:spree_completed_order_with_totals, retailer_id: spree_retailer.id)
  end

  before do
    current_user.update(email: 'user@hingeto.com')
    login_as(current_user, scope: :spree_user)
  end

  describe 'replace line item' do
    context 'when order is not paid for' do
      before do
        @old_variant = order.line_items.first.variant
        @old_variant.update(platform_supplier_sku: 'sku-1')
        @new_variant = create(:variant, platform_supplier_sku: 'sku-1')
      end

      xit 'replaces line item' do
        visit retailer_edit_order_line_items_path(order_id: order.internal_identifier)
        expect(page).to have_content @old_variant.name

        selector = order.line_items.first.id
        find("##{selector}").find("option[value='#{@new_variant.internal_identifier}']").
          select_option
        click_on('Replace Line Items')

        expect(page).to have_content @new_variant.name
        expect(order.reload.line_items.first.variant_id).to eq @new_variant.id
      end
    end

    context 'when order has been paid' do
      before do
        create(:payment, amount: order.total, order: order, state: 'completed')
        @old_variant = order.line_items.first.variant
        @old_variant.update(platform_supplier_sku: 'sku-2')
        @new_variant = create(:variant, platform_supplier_sku: 'sku-2')
      end

      xit 'dsiplays error' do
        visit retailer_edit_order_line_items_path(order_id: order.internal_identifier)
        expect(page).to have_content @old_variant.name

        selector = order.line_items.first.id
        find("##{selector}").find("option[value='#{@new_variant.internal_identifier}']").
          select_option
        click_on('Replace Line Items')

        expect(page).to have_content 'Cannot replace line items for paid order'
      end
    end
  end
end
