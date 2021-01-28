require 'rails_helper'

RSpec.describe 'Ordering a sample product', type: :feature do
  let(:retailer) { spree_retailer }

  before do
    current_user = retailer.users.first
    login_as(current_user, scope: :spree_user)
    license_taxonomy = create(:taxonomy, name: 'License')
    @license_taxon = create(:taxon, taxonomy: license_taxonomy)
  end

  before :all do
    @variant = create(:spree_variant_with_quantity, product: (create :spree_product_in_stock))
    @product = @variant.product
  end

  before do
    allow_any_instance_of(Spree::Product).to receive(:approved?).and_return(true)
    allow_any_instance_of(
      Spree::Supplier
    ).to receive(:allow_free_shipping_for_sample_products?).and_return true
  end

  describe 'buying sample product' do
    xit 'without a previous card', js: true do
      visit retailer_product_details_path(product_id: @product.internal_identifier)
      expect(page).to have_content(@product.name)

      click_button('Buy Sample Product')
      expect(page).to have_content('Enter Shipping Address')

      select_second_option('variant_id')
      fill_address
      click_button('Buy Sample')

      expect(page).to have_content('You have not added any card yet')
    end

    xit 'when there is an existing card', js: true do
      customer = create :stripe_customer, strippable: retailer
      create :stripe_card, stripe_customer: customer

      visit retailer_product_details_path(product_id: @product.internal_identifier)
      expect(page).to have_content(@product.name)

      click_button('Buy Sample Product')
      expect(page).to have_content('Enter Shipping Address')

      select_second_option('variant_id')
      fill_address
      click_button('Buy Sample')

      expect(page).not_to have_content('You have not added any card yet')
    end
  end

  def fill_address
    fill_in 'address_fields[first_name]',  with: Faker::Name.first_name
    fill_in 'address_fields[last_name]',  with: Faker::Name.last_name
    fill_in 'address_fields[address1]',  with: Faker::Address.street_address
    fill_in 'address_fields[city]',  with: 'Oakland'
    fill_in 'address_fields[name_of_state]',  with: 'California'
    fill_in 'address_fields[zipcode]',  with: Faker::Address.zip_code
  end

  def select_second_option(id)
    second_option_xpath = "//*[@id='#{id}']/option[2]"
    second_option = find(:xpath, second_option_xpath).text
    select(second_option, from: id)
  end
end
