class Retailer::AddressesController < Retailer::BaseController
  skip_before_action :confirm_paying_customer?
  skip_before_action :confirm_onboarded?

  def index; end

  def update_address
    attributes = set_default_address_attributes

    if current_retailer.update(attributes)
      flash[:notice] = 'Address updated successfully'
      redirect_to retailer_addresses_path
      return
    end

    flash.now[:alert] = "Error: Unable to update address: #{current_retailer.friendly_error}"
    render :index
  end

  def update_shopify_address
    flash[:notice] = 'Shopify store information is being updated. This may take up to 30s.'
    job = Spree::LongRunningJob.create(
      action_type: 'import',
      job_type: 'shopify_import',
      initiated_by: 'user',
      retailer_id: current_retailer.id
    )
    Shopify::UpdateInformationJob.perform_later(job.internal_identifier)
    redirect_to retailer_addresses_path
  end

  def set_default_shopify_location
    location_id = params[:location]
    if current_retailer.update(default_location_shopify_identifier: location_id)
      flash[:notice] = 'Default location updated'
    else
      flash[:alert] = 'Could not update default location'
    end
    redirect_to retailer_addresses_path
  end

  def get_shopify_locations
    begin
      current_retailer.init
      @locations = ShopifyAPI::Location.all.reject(&:legacy)
    rescue
      flash.now[:alert] = 'Could not get shopify locations'
    end

    respond_to do |format|
      format.js
    end
  end

  private

  def set_default_address_attributes
    attributes = address_params
    address_type = "#{params[:address_type]}_attributes"
    attributes[address_type][:first_name] = retailer.users.first.try(:first_name) || 'N/A'
    attributes[address_type][:last_name] = retailer.users.first.try(:last_name) || 'N/A'
    attributes[address_type][:phone] = retailer.phone.blank? ? 'N/A' : retailer.phone
    attributes
  end

  def address_params
    params.require(:retailer).permit(
      legal_entity_address_attributes: %i(id address1 address2 city zipcode name_of_state phone
                                          country_id business_name),
      shipping_address_attributes: %i(id address1 address2 city zipcode name_of_state phone
                                      country_id business_name)
    )
  end
end
