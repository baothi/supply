RSpec.shared_examples 'protects urls from non-hingeto users' do
  describe 'When logged in' do
    context 'as a non-hingeto user' do
      it 'cannot access flipper' do
        login_as(spree_supplier.users.first, scope: :spree_user)
        expect do
          subject
        end.to raise_error(ActionController::RoutingError)
      end
    end

    context 'as a hingeto user' do
      before do
        login_as(spree_supplier_user_with_hingeto_email, scope: :spree_user)
      end

      it 'can access flipper without errors' do
        expect do
          subject
        end.not_to raise_error(ActionController::RoutingError)
      end
    end
  end

  describe 'When not logged in' do
    it 'cannot access flipper' do
      expect do
        subject
      end.to raise_error(ActionController::RoutingError)
    end
  end
end
