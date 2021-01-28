require 'rails_helper'

RSpec.describe 'User Login Process', type: :feature do
  let(:user_password) { 'password' }
  let(:user) do
    u = create :spree_user
    u.password = user_password
    u.save!
    u
  end

  before do
    create :spree_team_member,
           user: user,
           teamable: spree_supplier
  end

  describe 'Filling signin form' do
    it 'signs user in with right email and password' do
      fill_sign_in_form
      expect(page).not_to have_content 'Invalid Email or password.'
      expect(page).to have_content 'Signed in successfully'
    end
  end

  describe 'Switching between teams' do
    context 'when user belongs to one team' do
      it 'does not contain link to Switch team' do
        fill_sign_in_form
        expect(page).to have_current_path '/supplier/dashboard'

        find('a.nav-link.navbar-avatar', match: :first).click
        expect(page).not_to have_content 'Switch to'
      end
    end

    context 'when user belongs 2 teams' do
      before do
        create :spree_team_member, user: user
      end

      it 'contains link to switch team' do
        fill_sign_in_form
        expect(page).to have_content 'Signed in successfully'

        find('a.nav-link.navbar-avatar', match: :first).click
        expect(page).to have_content 'Switch to'
      end
    end
  end

  def fill_sign_in_form
    visit new_spree_user_session_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user_password
    click_button 'Sign in'
  end
end
