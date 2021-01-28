class Retailer::TaxonsController < Retailer::BaseController
  before_action :set_taxon, only: %i(follow_unfollow add_products_to_shopify)
  before_action :create_long_running_job, only: :add_products_to_shopify

  def add_products_to_shopify
    @message = if @job.in_progress?
                 'There is currently a job in progress. You will be notified once its complete!'
               else
                 Shopify::AddTaxonProductsJob.perform_later(@job.internal_identifier)
                 'New products in this category are being added to your shopify store.'\
                 'You will get an email, once its done!'
               end

    respond_to { |format| format.js { render :add_products_to_shopify } }
  end

  def follow_unfollow
    @followed = follow_or_unfollow(@taxon)

    respond_to do |format|
      format.js { render :follow_unfollow }
      format.html { redirect_back fallback_location: retailer_products_list_path }
    end
  end

  private

  def set_taxon
    @taxon = Spree::Taxon.find_by(id: params[:id])
  end

  def follow_or_unfollow(taxon)
    if current_retailer.following?(taxon)
      current_retailer.stop_following(taxon)
      return false
    end

    current_retailer.follow(taxon)
    true
  end

  def create_long_running_job
    @job = Spree::LongRunningJob.find_or_create_by(
      action_type: 'export',
      job_type: 'products_export',
      initiated_by: 'user',
      retailer_id: current_retailer.id,
      option_1: @taxon.id,
      option_2: 'add_taxon_products_to_shopify'
    )
  end
end
