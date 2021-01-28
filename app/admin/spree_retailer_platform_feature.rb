ActiveAdmin.register Spree::RetailerPlatformFeature do
  actions :all, except: [:destroy]

  menu label: 'Retailer Plan Features', parent: 'Teams'

  controller do
    # def find_resource
    #   scoped_collection.where(slug: params[:id]).first!
    # end

    def update
      puts permitted_params.inspect
      resource.update(permitted_params[:retailer])
      redirect_to resource_path(resource), notice: 'Successfully updated!'
    end

    def permitted_params
      # params.permit(retailer:
      #                   %i(can_view_supplier_name
      #                      default_us_shipping_method_id
      #                      default_canada_shipping_method_id
      #                      default_rest_of_world_shipping_method_id
      #                      can_view_brand_name))
    end
  end

  member_action :update_preferences, method: :post do
    params[:retailer_platform_feature][:settings].each do |key, value|
      resource.set_setting(key, value)
    end
    resource.save
    redirect_to resource_path(resource), notice: 'Successfully updated!'
  end

  index download_links: false, pagination_total: false do
    selectable_column
    id_column

    column :id
    column :plan_name
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :plan_name
      row :created_at
    end

    panel 'Settings/Preferences' do
      render 'settings'
    end
  end
end
