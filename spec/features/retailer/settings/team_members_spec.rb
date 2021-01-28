require 'rails_helper'

RSpec.describe 'Team Members', type: :feature do
  before do
    @retailer = spree_retailer
    @team_member = @retailer.team_members.first
    @current_user = @team_member.user

    @admin_role = create :spree_role, name: Spree::Retailer::RETAILER_ADMIN
    @user2 = create :spree_user
    @retailer.team_members.create(user: @user2, role: @admin_role)
  end

  describe 'Visiting the team members page' do
    before do
      login_as(@current_user, scope: :spree_user)
      visit retailer_team_index_path
    end

    it 'contains the names of the retailer users and role name' do
      expect(page).to have_link("#{@current_user.first_name} #{@current_user.last_name}")
      expect(page).to have_link("#{@user2.first_name} #{@user2.last_name}")
      expect(page).to have_css('span', text: "#{@team_member.role.name.humanize.titleize}")
      expect(page).to have_css('span', text: "#{@user2.role.name.humanize.titleize}")
    end

    context 'when user is not retailer owner or admin' do
      before do
        role = create :spree_role, name: Spree::Retailer::RETAILER_LEGAL
        @team_member.update(role: role)
        @current_user.reload

        login_as(@current_user, scope: :spree_user)
        visit retailer_team_index_path
      end

      it 'cannot see the add-account panel and form' do
        expect(page).not_to have_content 'Add Account'
        expect(page).not_to have_css('form#new_user')
      end

      it 'does not see the "Remove Member" button in team member page' do
        within('table.table') do
          click_link "#{@user2.first_name} #{@user2.last_name}"
        end

        expect(page).to have_content('Remove Team Member')
        expect(page).not_to have_button('Remove Member')
      end
    end

    context 'when the user is the retailer_owner' do
      before do
        role = create :spree_role, name: Spree::Retailer::RETAILER_OWNER
        @team_member.update(role: role)
        @current_user.reload

        login_as(@current_user, scope: :spree_user)
        visit retailer_team_index_path
      end

      it 'can see the add-account panel and form' do
        expect(page).to have_content 'Add Account'
        expect(page).to have_css('form#new_user')
      end

      describe 'Adding Team Member' do
        it 'fills the add-account form and create new account' do
          user = attributes_for :spree_user
          within('form#new_user') do
            fill_in 'user_email', with: user[:email]
            fill_in 'user_first_name', with: user[:first_name]
            fill_in 'user_last_name', with: user[:last_name]
            select @admin_role.name.humanize.titleize, from: 'spree_role_id'

            click_button 'Add'
          end

          expect(page).to have_css('td', text: "#{user[:first_name]} #{user[:last_name]}")
          expect(page).to have_css('span', text: "#{@admin_role.name.humanize.titleize}")
        end
      end

      describe 'Changing Team Member Role' do
        it 'selects the first team member and change the role' do
          within('table.table') do
            click_link "#{@user2.first_name} #{@user2.last_name}"
          end
          expect(page).to have_content('Team Member Information')
          expect(page).to have_selector("input[value='#{@user2.email}']")
          expect(page).to have_select('team_member_role_id',
                                      selected: @user2.role.name.humanize.titleize)

          select @admin_role.name.humanize.titleize, from: 'team_member_role_id'

          click_button 'Update Role'

          expect(page).to have_content "#{@user2.full_name}'s role updated"
        end
      end

      describe 'Deleting team memner' do
        it 'selects the first team member and deletes it' do
          within('table.table') do
            click_link "#{@user2.first_name} #{@user2.last_name}"
          end

          expect(page).to have_content('Team Member Information')
          expect(page).to have_content('Remove Team Member')
          expect(page).to have_button('Remove Member')

          click_button 'Remove Member'

          expect(page).to have_content "#{@user2.full_name} was successfully removed."
        end

        context 'when user select there own account' do
          it 'does not see the remove button' do
            within('table.table') do
              click_link "#{@current_user.first_name} #{@current_user.last_name}"
            end

            expect(page).to have_content('Team Member Information')
            expect(page).to have_content('Remove Team Member')
            expect(page).to have_content('You cannot remove your own account')
            expect(page).not_to have_button('Remove Member')
          end
        end
      end
    end
  end
end
