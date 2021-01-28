require 'rails_helper'

RSpec.describe 'Advanced', type: :feature do
  before do
    @retailer = spree_retailer
    @team_member = @retailer.team_members.first
    @current_user = @team_member.user

    @admin_role = create :spree_role, name: Spree::Retailer::RETAILER_ADMIN
    @user2 = create :spree_user
    @retailer.team_members.create(user: @user2, role: @admin_role)
  end

  # describe 'Visiting the advanced settings page' do
  #   before do
  #     login_as(@current_user, scope: :spree_user)
  #     visit retailer_settings_advanced_index_path
  #   end
  #
  #   it 'contains "Advanced" and "Ownership Transfer" text' do
  #     expect(page).to have_content 'Advanced'
  #     expect(page).to have_content 'Ownership Transfer'
  #   end
  #
  #   context 'when user is not retailer owner' do
  #     before do
  #       role = create :spree_role, name: Spree::Retailer::RETAILER_LEGAL
  #       @team_member.update(role: role)
  #       @current_user.reload
  #
  #       login_as(@current_user, scope: :spree_user)
  #       visit retailer_settings_advanced_index_path
  #     end
  #
  #     it 'cannot see the transfer ownership form' do
  #       expect(page).to have_content 'Only current owner can transfer ownership'
  #       expect(page).not_to have_button('Transfer')
  #     end
  #   end
  #
  #   context 'when the user is the retailer_owner' do
  #     before do
  #       role = create :spree_role, name: Spree::Retailer::RETAILER_OWNER
  #       @team_member.update(role: role)
  #       @current_user.reload
  #
  #       login_as(@current_user, scope: :spree_user)
  #       visit retailer_settings_advanced_index_path
  #     end
  #
  #     it 'can see the transfer button' do
  #       expect(page).to have_button('Transfer')
  #       expect(page).to have_select('new_owner')
  #     end
  #
  #     describe 'Transfering ownership' do
  #       it 'transfers ownership to the selected member' do
  #         select @user2.full_name_for_display, from: 'new_owner'
  #
  #         click_button 'Transfer'
  #
  #         expect(page).to have_content 'Ownership tranfered'
  #       end
  #     end
  #   end
  # end
end
