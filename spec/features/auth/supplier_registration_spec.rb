require 'rails_helper'

RSpec.describe 'Non-Shopify Supplier Registration' do
  # context 'required details are not well filled' do
  #   it 'filled returns with error' do
  #     visit register_supplier_path(ref: ENV['SUPPLIER_SIGNUP_REF'])
  #     fill_in 'Supplier Business Name', with: Faker::Company.name
  #     fill_in 'Email', with: Faker::Internet.email
  #     fill_in 'First Name', with: Faker::Name.first_name
  #     fill_in 'Last Name', with: Faker::Name.last_name
  #     fill_in 'Password', with: 'password'
  #     fill_in 'Confirm Password', with: 'password-missmatch'
  #     check 'inputCheckbox'
  #     click_button 'Sign Up'
  #
  #     expect(page).to have_content 'Errors!!'
  #   end
  # end
  #
  # context 'when all field is filled correctly' do
  #   it 'creates user and goes to dashboard' do
  #     visit register_supplier_path(ref: ENV['SUPPLIER_SIGNUP_REF'])
  #     fill_in 'Supplier Business Name', with: Faker::Company.name
  #     fill_in 'Email', with: Faker::Internet.email
  #     fill_in 'First Name', with: Faker::Name.first_name
  #     fill_in 'Last Name', with: Faker::Name.last_name
  #     fill_in 'Password', with: 'password'
  #     fill_in 'Confirm Password', with: 'password'
  #     check 'inputCheckbox'
  #     click_button 'Sign Up'
  #
  #     expect(page).to have_content 'Welcome to Hingeto Supply'
  #   end
  # end
end
