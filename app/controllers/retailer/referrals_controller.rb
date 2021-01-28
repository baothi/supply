class Retailer::ReferralsController < Retailer::BaseController
  # skip_before_action :enforce_limited_access

  def new
    @referral = Spree::SupplierReferral.new
  end

  def create
    @referral = Spree::SupplierReferral.new(referral_params)
    @referral.spree_retailer_id = current_retailer.id
    if @referral.save
      redirect_to retailer_referrals_path
    else
      render :new
    end
  end

  def index
    @referrals = Spree::SupplierReferral.
                 where(spree_retailer_id: current_retailer.id).
                 order('created_at desc').all
  end

  private

  def referral_params
    params.require(:supplier_referral).permit(
      :name, :url, :has_relationship
    )
  end
end
