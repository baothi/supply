class Supplier::ShippingMethodsController < Supplier::BaseController
  def index
    @couriers = Spree::Courier.all
  end

  def show
    validate_service_code
    set_shipping_method

    # Now find mapping
    locate_mapping
  end

  def update_mapping
    set_shipping_method
    locate_mapping
    value = mapping_params[:value]
    @mapped_shipping_method.value = value

    if @mapped_shipping_method.save
      flash[:notice] = "Successfully mapped #{@shipping_method.name} to #{value} "
    else
      flash[:alert] = "There was an error mapping #{value} "
    end
    redirect_to supplier_shipping_methods_path
    nil
  end

  private

  def mapping_params
    params.
      require(:mapped_shipping_method).
      permit(:value)
  end

  def set_shipping_method
    @shipping_method = Spree::ShippingMethod.find_by_service_code!(
      params[:service_code].upcase
    )
    @courier = @shipping_method.courier
  end

  def locate_mapping
    @mapped_shipping_method = Spree::MappedShippingMethod.where(
      teamable: current_supplier,
      shipping_method_id: @shipping_method.id
    ).first
    if @mapped_shipping_method.nil?
      @mapped_shipping_method = Spree::MappedShippingMethod.new
      @mapped_shipping_method.teamable = current_supplier
      @mapped_shipping_method.shipping_method_id = @shipping_method.id
    end
    @mapped_shipping_method
  end

  def validate_service_code
    raise 'Service code is required' if
        params[:service_code].blank?
  end
end
