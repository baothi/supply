class Retailer::EmailsController < ApplicationController
  before_action :authenticate_spree_user!, if: :not_active_admin_route_or_is_review_app?
  def unsubscribe
    retailer = Spree::Retailer.find_by_unsubscribe_hash(params[:unsubscribe_hash])
    unless retailer.unsubscribe.include? params[:subscription]
      case params[:subscription]
      when "did_not_install_app"
        retailer.unsubscribe << params[:subscription]
        retailer.save!
      when "retailer_not_sold_any_products_in_7days"
        retailer.unsubscribe << params[:subscription]
        retailer.save!
      when "did_not_add_product"
        retailer.unsubscribe << params[:subscription]
        retailer.save!
      when "did_not_add_more_than_ten_product"
        retailer.unsubscribe << params[:subscription]
        retailer.save!
      end
    end
  end
end
