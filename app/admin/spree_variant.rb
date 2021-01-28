ActiveAdmin.register Spree::Variant do
  menu label: 'Variants', parent: 'Products'

  actions :all, except: %i(new destroy)

  # filter :supplier_id, label: 'Product ID'
  filter :supplier
  filter :product_id, label: 'Product ID'
  filter :sku
  filter :supplier_id, label: 'Supplier ID'
  filter :internal_identifier, label: 'Variant Internal Identifier', as: :string

  scope :price_managed_by_master_sheet
  scope :price_not_managed_by_master_sheet
  # scope :price_managed_by_shopify
  # scope :price_managed_by_upload
  scope :submission_compliant
  scope :not_submission_compliant
  scope :not_discontinued_and_submission_compliant
  scope :has_approved_product_but_not_submission_compliant
  scope :has_approved_product_but_not_managed_by_master_sheet

  controller do
    def scoped_collection
      super.includes :supplier, :product, :stock_items
      end_of_association_chain.where(is_master: false)
    end

    def find_resource
      scoped_collection.where(id: params[:id]).first!
    end

    def update
      # puts permitted_params.inspect
      resource.update(permitted_params[:variant])
      redirect_to resource_path(resource), notice: 'Successfully updated!'
    end

    def permitted_params
      params.permit(variant:
                        %i(original_supplier_sku
                           barcode
                           gtin
                           discontinue_on
                           supplier_color_value
                           supplier_size_value
                           supplier_size_option
                           supplier_color_option
                           platform_size_option_id
                           platform_color_option_id
                           width
                           height
                           depth
                           weight
                           weight_unit
                           shopify_vendor
                           supplier_product_type))
    end
  end

  action_item :update_compliance, only: :show do
    link_to 'Run Compliance Check', action: :update_compliance
  end

  member_action :crop_image, method: :post do
    variant = Spree::Product.find_by_slug(params[:id])
    image = Spree::Image.find(params[:image_id])
    image.upload_2_cloudinary!
    redirect_to resource_path(variant), notice: 'Image Cropped Successfully'
  end

  member_action :update_compliance, method: :get do
    # Simply Touching will force a compliance refresh
    resource.refresh_compliance_now!
    redirect_to resource_path(resource),
                notice: 'Successfully Updated Compliance'
  end

  show do
    attributes_table title: 'Basic Details' do
      row :supplier
      row :product
      row :created_at
      row :dsco_identifier
      row :platform_supplier_sku
      row :original_supplier_sku
      row :barcode
      row :gtin
      row :discontinue_on
      row :image_urls, hint: 'Please do not edit this unless you are on the engineering team'
    end

    attributes_table title: 'Compliance Management' do
      row :submission_compliant
      row :submission_compliance_log
      row :submission_compliance_status_updated_at
      # Market
      # row :marketplace_compliant
      # row :marketplace_compliance_log
      # row :marketplace_compliance_status_updated_at
    end

    attributes_table title: 'Inventory Management' do
      row :available_quantity
    end

    attributes_table title: 'Price Management' do
      row :price_management
      row :master_msrp
      row :master_cost
      row :master_map
    end

    attributes_table title: 'Size/Color Options' do
      row :supplier_color_value
      row :supplier_size_value
      row :supplier_size_option
      row :supplier_color_option
    end

    attributes_table title: 'Platform Details' do
      row :platform_size_option
      row :platform_color_option
    end

    attributes_table title: 'Dimensions' do
      row :width
      row :height
      row :depth
      row :weight
      row :weight_unit
    end

    attributes_table title: 'Images' do
      spree_variant.images.each do |img|
        columns do
          column do
            image_tag(img&.attachment&.url(:large))
          end
          column do
            button_to 'Crop Image', crop_image_admin_spree_variant_path,
                      data: { confirm: 'Are you sure', disable_with: 'Cropping...' },
                      params: { image_id: img.id }
          end
        end
      end
    end
  end

  form do |f|
    f.semantic_errors

    inputs do
      input :original_supplier_sku
      input :barcode
      input :gtin
      input :discontinue_on
      input :image_urls, hint: 'Please do not edit this unless you are on the engineering team'
    end

    # inputs do
    #   input :price_management, as: :select, collection: ['shopify', 'upload']
    #   input :map_price
    #   input :msrp_price
    #   input :cost_price
    # end

    inputs do
      input :supplier_color_value, as: :string
      input :supplier_size_value
      input :supplier_size_option
      input :supplier_color_option
    end

    inputs do
      input :platform_size_option
      input :platform_color_option
    end

    inputs do
      input :width
      input :height
      input :depth
      input :weight
      input :weight_unit
    end

    actions
  end

  index download_links: false, pagination_total: false do
    selectable_column

    column :supplier
    column :product
    column :original_supplier_sku
    column :platform_supplier_sku
    column :master_msrp
    column :master_cost
    # column :available_on
    column :price
    column :discontinue_on
    column :supplier_color_value
    column :supplier_size_value
    column :available_quantity
    column :price_management
    # column :tax_category

    actions
  end
end
