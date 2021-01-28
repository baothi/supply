module Support
  module SupplierApplicationFlowHelper
    def fill_and_submit_application_form
      @supplier_name = Faker::Company.name
      email = Faker::Internet.email
      website = Faker::Internet.url
      first_name = Faker::Name.first_name
      last_name = Faker::Name.last_name
      phone_number = Faker::PhoneNumber.cell_phone
      facebook_url = Faker::Internet.user_name(5..12, [])
      instagram_url = Faker::Internet.user_name(5..12, [])
      ecommerce_platform = Spree::SupplierApplication.ecommerce_platforms.keys.sample.to_s

      fill_in :supplier_application_draft_supplier_name, with: @supplier_name
      fill_in :supplier_application_draft_website, with: website
      fill_in :supplier_application_draft_email, with: email
      fill_in :supplier_application_draft_first_name, with: first_name
      fill_in :supplier_application_draft_last_name, with: last_name
      fill_in :supplier_application_draft_phone_number, with: phone_number
      fill_in :supplier_application_draft_facebook_url, with: facebook_url
      fill_in :supplier_application_draft_instagram_url, with: instagram_url
      select ecommerce_platform, from: :supplier_application_draft_ecommerce_platform

      click_button 'Next'
    end
  end
end
