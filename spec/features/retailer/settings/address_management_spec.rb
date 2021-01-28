require 'rails_helper'

RSpec.describe 'Address Management', type: :feature do
  let(:address_attr) { attributes_for :spree_address }

  before do
    login_as(spree_retailer.users.first, scope: :spree_user)
    @state = Faker::Address.state
  end

  describe 'Visiting the address management page' do
    it 'Contains "Default, Legal Entity and Shipping Address"' do
      visit retailer_addresses_path

      within('div.page-content') do
        expect(page).to have_content('Default Information')
        expect(page).to have_content('Legal Entity Address')
        expect(page).to have_content('Shipping Address')
      end
    end

    it 'contains 3 forms and 2 buttons' do
      visit retailer_addresses_path

      within('div.page-content') do
        expect(page).to have_css('form.edit_retailer', count: 3)
        expect(page).to have_css('button.btn.btn-primary.form-button', count: 3)
      end
    end
  end

  describe 'filling the LEGAL ENTITY address form' do
    context 'when all field is properly filled' do
      it 'redirects to address page with success message' do
        visit retailer_addresses_path

        within('form#edit_retailer_legal_entity_address') do
          fill_in 'retailer[legal_entity_address_attributes][business_name]',
                  with: address_attr[:business_name]
          fill_in 'retailer[legal_entity_address_attributes][address1]',
                  with: address_attr[:address1]
          fill_in 'retailer[legal_entity_address_attributes][city]', with: address_attr[:city]
          fill_in 'retailer[legal_entity_address_attributes][zipcode]', with: address_attr[:zipcode]

          fill_in 'retailer[legal_entity_address_attributes][name_of_state]', with:  @state

          click_button 'Update Legal Entity Address'
        end

        expect(page).to have_css('div.alert.alert-success', text: 'Address updated successfully')
      end
    end

    context 'when the address1 is NOT fill' do
      it 'renders the addresses page with error message' do
        visit retailer_addresses_path

        within('form#edit_retailer_legal_entity_address') do
          fill_in 'retailer[legal_entity_address_attributes][business_name]',
                  with: address_attr[:business_name]
          fill_in 'retailer[legal_entity_address_attributes][city]', with: address_attr[:city]
          fill_in 'retailer[legal_entity_address_attributes][zipcode]', with: address_attr[:zipcode]

          fill_in 'retailer[legal_entity_address_attributes][name_of_state]', with:  @state

          click_button 'Update Legal Entity Address'
        end

        expect(page).to have_css 'div.alert.alert-danger'
        expect(page).to have_content 'Unable to update address'
      end
    end
  end

  describe 'filling the SHIPPING address form' do
    context 'when all field is properly filled' do
      it 'redirects to address page with success message' do
        visit retailer_addresses_path

        within('form#edit_retailer_shipping_address') do
          fill_in 'retailer[shipping_address_attributes][business_name]',
                  with: address_attr[:business_name]
          fill_in 'retailer[shipping_address_attributes][address1]',
                  with: address_attr[:address1]
          fill_in 'retailer[shipping_address_attributes][city]', with: address_attr[:city]
          fill_in 'retailer[shipping_address_attributes][zipcode]', with: address_attr[:zipcode]

          fill_in 'retailer[shipping_address_attributes][name_of_state]', with:  @state

          click_button 'Update Shipping Address'
        end

        expect(page).to have_css('div.alert.alert-success', text: 'Address updated successfully')
      end
    end

    context 'when the address1 is NOT fill' do
      it 'renders the addresses page with error message' do
        visit retailer_addresses_path

        within('form#edit_retailer_shipping_address') do
          fill_in 'retailer[shipping_address_attributes][business_name]',
                  with: address_attr[:business_name]
          fill_in 'retailer[shipping_address_attributes][city]', with: address_attr[:city]
          fill_in 'retailer[shipping_address_attributes][zipcode]', with: address_attr[:zipcode]

          fill_in 'retailer[shipping_address_attributes][name_of_state]', with:  @state

          click_button 'Update Shipping Address'
        end

        expect(page).to have_css 'div.alert.alert-danger'
        expect(page).to have_content 'Unable to update address'
      end
    end
  end
end
