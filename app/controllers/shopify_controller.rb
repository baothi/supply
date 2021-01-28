class ShopifyController < ActionController::Base
  include ShopifyInstaller

  def install
    login(params[:shop])
  end
end
