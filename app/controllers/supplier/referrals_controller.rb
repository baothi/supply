class Supplier::ReferralsController < Supplier::BaseController
  skip_before_action :enforce_limited_access

  def new
    @referral = Spree::RetailerReferral.new
  end

  def create
    @referral = Spree::RetailerReferral.new(referral_params)
    @referral.spree_supplier_id = current_supplier.id
    if @referral.save
      redirect_to supplier_referrals_path
    else
      render :new
    end
  end

  def index
    @referrals = Spree::RetailerReferral.
                 where(spree_supplier_id: current_supplier.id).
                 order('created_at desc').all
  end

  private

  def referral_params
    params.require(:retailer_referral).permit(
      :name, :url, :has_relationship
    )
  end
end
