class Supplier::SettingsController < Supplier::BaseController
  before_action :convert_param, only: :update

  def update
    current_supplier.update(supplier_params)
    flash[:notice] = 'Saved'
    redirect_back(fallback_location: supplier_settings_shopify_path)
  end

  private

  def convert_param
    return unless params[:supplier][:default_markup_percentage].present?

    params[:supplier][:default_markup_percentage] =
      params[:supplier][:default_markup_percentage].to_f / 100
  end

  def supplier_params
    params.require(:supplier).permit(:instance_type, :default_markup_percentage)
  end
end
