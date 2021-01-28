require 'rails_helper'

RSpec.describe 'Visiting the home page', type: :feature do
  it 'can visit the page from login page' do
    visit new_spree_user_session_path
    click_link 'Reset Password'
    expect(page).to have_current_path new_spree_user_password_path
  end

  context 'when in the forgot password page' do
    before do
      visit new_spree_user_password_path
    end

    it 'renders password resent page successfully' do
      expect(page).to have_current_path(new_spree_user_password_path)
      expect(page).to have_content 'Forgot Your Password?'
    end
  end

  context 'when requesting password reset' do
    let(:user) { Spree::User.last }

    it 'returns to login page and send email' do
      visit new_spree_user_password_path
      # fill_in 'spree_user[shopify_slug]', with: user.shopify_slug
      fill_in 'spree_user[email]', with: user.email

      click_button 'Send me reset password instruction'

      expect(page).to have_current_path new_spree_user_session_path
      expect(page).to have_content 'Please check your email.'
    end
  end

  describe 'changing password' do
    it 'visits the new password page and choose a new password' do
      user = create :spree_user
      token = user.send(:set_reset_password_token)

      visit edit_spree_user_password_path(reset_password_token: token)
      expect(page).to have_current_path(
        edit_spree_user_password_path(reset_password_token: token)
      )

      # binding.pry

      fill_in 'spree_user[password]', with: 'password'
      fill_in 'spree_user[password_confirmation]', with: 'password'
      click_button 'Change My Password'

      # binding.pry

      expect(page).to have_content 'Your password has been changed successfully'
      expect(page.current_path).to include '/login'
    end
  end
end
