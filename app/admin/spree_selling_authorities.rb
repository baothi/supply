ActiveAdmin.register Spree::SellingAuthority do
  permit_params :retailer_id, :permittable_string, :permission
  menu label: 'Selling Authorities', parent: 'Products'

  form do |f|
    f.inputs 'Selling Authorities' do
      f.input :permittable_string,
              as: :select,
              label: 'Permittable',
              input_html: { id: 'selling-authority-permittable-string' },
              hint: "Object you're setting permission on"

      f.input :permission,
              as: :select,
              hint: 'Whitelist or blacklist permission'
      f.input :retailer,
              input_html: { id: 'selling-authority-retailer-id' },
              hint: "The retailer you're applying the permission on"
    end

    f.actions
  end

  index download_links: false, pagination_total: false do
    selectable_column
    id_column

    column :retailer
    column 'Permittable Type' do |selling_authority|
      selling_authority.permittable_type.split('::').last
    end
    column :permittable
    column :permission
    actions
  end

  collection_action :search_permittable do
    result = if params[:edit_id].present?
               Spree::SellingAuthority.current_permittable_opts(params[:edit_id])
             else
               Spree::SellingAuthority.permittable_opts(params[:q])
             end
    render json: result
  end

  collection_action :search_retailers do
    result = Spree::Retailer.select2_search(params[:q])
    render json: result
  end

  controller do
    def create
      @selling_authority = Spree::SellingAuthority.create(permitted_params[:selling_authority])
      redirect_to admin_spree_selling_authority_path(@selling_authority)
    end

    def update
      @selling_authority = resource.update(permitted_params[:selling_authority])
      redirect_to admin_spree_selling_authority_path(resource)
    end
  end
end
