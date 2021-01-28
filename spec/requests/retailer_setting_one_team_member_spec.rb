require 'rails_helper'

RSpec.describe 'Retailer Setting', type: :request do
  before do
    retailer = spree_retailer

    sign_in(retailer.users.first)

    allow(Spree::Retailer).to(
      receive(:locate_by_host).and_return(spree_retailer)
    )

    @team_member = create(:spree_team_member, teamable: spree_retailer)
    # allow_any_instance_of(Spree::Retailer).to(
    #   receive_message_chain(:team_members, :find_by).and_return(@team_member)
    # )
  end

  describe 'GET /retailer/settings/team/member/:internal_identifier' do
    it 'renders the team_member_settings view' do
      get "http://localhost:3000/retailer/settings/team/member/#{@team_member.internal_identifier}"
      expect(assigns(:team_member)).to be_a Spree::TeamMember
      expect(response).to render_template(:member)
    end
  end

  describe 'PATCH /retailer/settings/team/update_account' do
    before do
      @role = create(:spree_role, name: Spree::Retailer::RETAILER_ADMIN)
    end

    context 'when team member update fails' do
      before do
        allow_any_instance_of(Spree::TeamMember).to receive(:update).and_return(false)
      end

      it 'renders the team/member template' do
        patch(
          'http://localhost:3000/retailer/settings/team/update_account',
          params: {
            team_member: {
              internal_identifier: @team_member.internal_identifier, role_id: @role.id
            }
          }
        )

        expect(response).to render_template(:member)
        expect(response.body).to include 'Error updating team member'
      end
    end

    context 'when team member is udpated successful' do
      it 'redirects to the settings/team/member/:id page' do
        patch(
          'http://localhost:3000/retailer/settings/team/update_account',
          params: {
            team_member: {
              internal_identifier: @team_member.internal_identifier, role_id: @role.id
            }
          }
        )

        expect(flash[:notice]).to include "#{@team_member.user.full_name}'s role updated"
        expect(response).to redirect_to(retailer_team_index_path)
      end
    end
  end
end
