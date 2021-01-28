module RequestSpecHelper
  include Warden::Test::Helpers

  def self.included(base)
    base.before { Warden.test_mode! }
    base.after { Warden.test_reset! }
  end

  def sign_in(user)
    login_as(user, scope: :spree_user)
  end

  def sign_out(_resource)
    logout(user, scope: :spree_user)
  end
end
