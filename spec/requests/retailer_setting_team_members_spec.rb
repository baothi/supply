require 'rails_helper'

RSpec.describe 'Retailer Setting', type: :request do
  before do
    current_team_member = spree_retailer.team_members.first

    role = create :spree_role, name: Spree::Retailer::RETAILER_OWNER
    current_team_member.update(role: role)

    @current_user = current_team_member.user

    sign_in(@current_user)

    allow(Spree::Retailer).to(
      receive(:locate_by_host).and_return(spree_retailer)
    )
  end

  describe 'GET /retailer/settings/team' do
    it 'renders the team/index view' do
      get 'http://localhost:3000/retailer/settings/team'
      expect(response).to render_template(:index)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /retailer/settings/team/add_account' do
    before do
      @role = create(:spree_role, name: Spree::Retailer::RETAILER_ADMIN)
    end

    context 'when user with email already exists in current team' do
      it 'redirects to the retailer/settings/team page' do
        post(
          'http://localhost:3000/retailer/settings/team/add_account',
          params: {
            user: {
              email: @current_user.email,
              first_name: Faker::Name.first_name,
              last_name: Faker::Name.last_name,
              password: Faker::Internet.password
            },
            spree_role_id: @role.id
          }
        )

        expect(flash[:alert]).to eq 'Email already in use within team'
        expect(response).to redirect_to('/retailer/settings/team')
      end
    end

    context 'when adding team member fails' do
      before do
        allow_any_instance_of(Spree::Retailer).to receive(:add_team_member).and_return(false)
      end

      it 'redirects to the settings/team page' do
        post(
          'http://localhost:3000/retailer/settings/team/add_account',
          params: {
            user: {
              email: Faker::Internet.email,
              first_name: Faker::Name.first_name,
              last_name: Faker::Name.last_name,
              password: Faker::Internet.password
            },
            spree_role_id: @role.id
          }
        )

        expect(flash[:alert]).to eq 'Error creating new account'
        expect(response).to redirect_to('/retailer/settings/team')
      end
    end

    context 'when team members is added successful' do
      before do
        # allow_any_instance_of(Spree::Retailer).to receive(:add_team_member).and_return(true)
      end

      let(:make_request) do
        post(
          'http://localhost:3000/retailer/settings/team/add_account',
          params: {
            user: {
              email: Faker::Internet.email,
              first_name: Faker::Name.first_name,
              last_name: Faker::Name.last_name,
              password: Faker::Internet.password
            },
            spree_role_id: @role.id
          }
        )
      end

      it 'redirects to the settings/team page with success message' do
        make_request
        expect(flash[:notice]).to eq 'User added successfully'
        expect(response).to redirect_to('/retailer/settings/team')
      end

      it 'changes count of Spree::User record' do
        expect { make_request }.to change(Spree::User, :count).by 1
      end

      it 'changes count of Spree::TeamMember record' do
        expect { make_request }.to change(Spree::TeamMember, :count).by 1
      end
    end
  end
end
