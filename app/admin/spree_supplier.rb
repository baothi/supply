ActiveAdmin.register Spree::Supplier do
  # config.filters = false

  scope :awaiting_access
  scope :having_access

  filter :name
  filter :shop_owner
  filter :shopify_url

  menu label: 'Supplier', parent: 'Teams'

  actions :index, :show, :edit, :update

  # permit_params :title, :content, :publisher_id, role_ids: []

  controller do
    include CommitWrap

    def find_resource
      scoped_collection.where(slug: params[:id]).first!
    end

    # For some reason, I am needing to add this to ActiveAdmin for us
    # otherwise udpates aren't properly working
    def update
      puts permitted_params.inspect
      resource.update(permitted_params[:supplier])
      # resource.update(permitted_params)
      redirect_to resource_path(resource), notice: 'Successfully updated!'
    end

    def permitted_params
      params.permit(supplier:
                        [:instance_type,
                         :display_name,
                         :default_markup_percentage,
                         :shopify_product_unique_identifier,
                         :dsco_identifier,
                         :edi_identifier,
                         :logo,
                         shipping_zone_ids: []])
    end
  end

  action_item :run_compliance_on_products, only: :show do
    link_to 'Run Compliance Checks on All Products', action: :run_compliance_on_products
  end

  # action_item :update_product_categories, only: :show do
  #   link_to 'Refresh Product Categories', update_product_categories_path(resource)
  # end

  action_item :export_dsco_orders, only: :show, if: proc { resource.dsco_identifier.present? } do
    link_to 'Export DSCO Orders', export_dsco_orders_path(resource)
  end

  # action_item :update_product_categories, only: :show do
  #   link_to 'Map Product Categories', map_product_categories_path(resource)
  # end

  action_item :grant_access, only: :show do
    link_to "#{spree_supplier.access_granted? ? 'Revoke' : 'Grant'} access", action: :grant_access
  end

  # TODO: This can be enabled later, when we'd need to have active/inactive users handled from admin
  # action_item :toggle_supplier_activation, only: :show do
  #   link_to "Set Supplier #{spree_supplier.active? ? 'Inactive' : 'Active'}",
  #           action: :toggle_supplier_activation, active: !spree_supplier.active?
  # end

  member_action :run_compliance_on_products, method: :get do
    min_id = Spree::Product.where(supplier_id: resource.id).minimum(:id)
    max_id = Spree::Product.where(supplier_id: resource.id).maximum(:id)
    product_count = resource.products.count
    num_emails = if product_count < 500
                   1
                 else
                   product_count % 500
                 end
    Spree::Product.update_all_cached_compliance_status_info!(min_id, max_id, 500, resource.id)

    redirect_to :back,
                notice: I18n.t('products.compliance.check_on_all_supplier_products_confirmation',
                               product_count: product_count,
                               num_emails: num_emails)
  end

  member_action :download_products, method: :get do
    download_images = params[:download_images] == '1'
    resource.download_shopify_products!(download_images)

    redirect_to resource_path(resource), notice: 'Products are being synced in background'
  end

  member_action :append_dsco_msrp, method: :post do
    begin
      ActiveRecord::Base.transaction do
        job = Spree::LongRunningJob.new(
          action_type: 'import',
          job_type: 'products_import',
          initiated_by: 'user',
          supplier_id: resource.id
        )
        job.input_csv_file = params[:file]
        job.save!

        execute_after_commit do
          Dsco::Product::BatchMsrpPriceAppendWorker.perform_async(job.internal_identifier)
        end
      end
      flash[:notice] = 'Calculating MSRPs.. Will email once complete'
    rescue => e
      flash[:alert] = "Could not upload #{e}"
    end
    redirect_to resource_path(resource)
  end

  member_action :upload_variant_prices, method: :post do
    begin
      ActiveRecord::Base.transaction do
        job = Spree::LongRunningJob.new(
          action_type: 'import',
          job_type: 'products_import',
          initiated_by: 'user',
          supplier_id: resource.id
        )
        job.input_csv_file = params[:file]
        job.save!

        execute_after_commit do
          Shopify::Variant::PriceUploadWorker.perform_async(job.internal_identifier)
        end
      end
      flash[:notice] = 'Uploading Prices'
    rescue => e
      flash[:alert] = "Could not upload #{e}"
    end
    redirect_to resource_path(resource)
  end

  member_action :upload_variant_size_and_color, method: :post do
    begin
      ActiveRecord::Base.transaction do
        job = Spree::LongRunningJob.new(
          action_type: 'import',
          job_type: 'products_import',
          initiated_by: 'user',
          supplier_id: resource.id
        )
        job.input_csv_file = params[:file]
        job.save!

        execute_after_commit do
          Shopify::Variant::OptionsUploadWorker.perform_async(job.internal_identifier)
        end
      end
      flash[:notice] = 'Uploading Size and color'
    rescue => e
      flash[:alert] = "Could not upload #{e}"
    end
    redirect_to resource_path(resource)
  end

  member_action :download_product_images, method: :get do
    force_refresh = params[:force_refresh] == '1'
    resource.download_shopify_product_images!(force_refresh)

    redirect_to resource_path(resource), notice: 'Images are being downloaded in background'
  end

  member_action :download_shipping_methods, method: :get do
    resource.download_shipping_methods

    redirect_to resource_path(resource), notice: 'Shipping methods are being downloaded'
  end

  member_action :upload_shipping_methods, method: :post do
    resource.upload_shipping_methods(params[:file])

    redirect_to resource_path(resource), notice: 'Shipping methods are being uploaded in background'
  end

  member_action :batch_import_dsco_products, method: :post do
    job = Spree::LongRunningJob.new(
      action_type: 'import',
      job_type: 'products_import',
      initiated_by: 'user',
      supplier_id: resource.id
    )
    job.input_csv_file = params[:file]
    if job.save!
      Dsco::Product::BatchImportJob.perform_later(job.internal_identifier)
      flash[:notice] = 'Products are being imported'
    else
      flash[:alert] = 'Could not import products'
    end
    redirect_to resource_path(resource)
  end

  member_action :batch_import_dsco_fulfillments, method: :post do
    job = Spree::LongRunningJob.new(
      action_type: 'import',
      job_type: 'fulfillments_import',
      initiated_by: 'user',
      supplier_id: resource.id
    )
    job.input_csv_file = params[:file]

    if job.save!
      Dsco::Fulfillment::BatchImportJob.perform_later(job.internal_identifier)
      flash[:notice] = 'Fulfillments are being imported'
    else
      flash[:alert] = 'Could not import fulfillments'
    end
    redirect_to resource_path(resource)
  end

  member_action :grant_access, method: :get do
    begin
      supplier = Spree::Supplier.find_by!(slug: params[:id])
      access   = supplier.access_granted? ? :revoke : :grant
      supplier.__send__("#{access}_access!")
      redirect_to :back, notice: "Access #{supplier.access_granted? ? 'Granted' : 'Revoked'}"
    rescue ActiveRecord::RecordNotFound => e
      redirect_to :back, notice: e.message
    end
  end

  # TODO: This can be enabled later, when we'd need to have active/inactive users handled from admin
  # member_action :toggle_supplier_activation, method: :get do
  #   supplier = Spree::Supplier.find_by(slug: params[:id])
  #
  #   if supplier.update(active: params[:active])
  #     redirect_to :back, notice: "Supplier set as
  #     #{supplier.active? ? 'Active' : 'Inactive'}"
  #   else
  #     redirect_to :back, notice: "An error Occured while
  #     #{supplier.active? ? 'activating' : 'deactivating'} Retailer"
  #   end
  # end

  member_action :update_preferences, method: :post do
    params[:supplier][:settings].each do |key, value|
      resource.set_setting(key, value)
    end
    resource.save
    redirect_to resource_path(resource), notice: 'Successfully updated!'
  end

  index download_links: false, pagination_total: false  do
    selectable_column
    column :id
    column :instance_type
    column :name do |supplier|
      link_to supplier.name, admin_spree_supplier_path(supplier)
    end
    column :eligible_shipping_zones_list
    column :shop_owner
    column :shopify_url do |supplier|
      link_to supplier.shopify_url, "http://#{supplier.shopify_url}", target: '_blank'
    end
    column 'Users' do |supplier|
      supplier.users.count
    end
    column 'Referrals count', &:number_of_referrals
    column 'Installed At', &:created_at
    column :active
    column :access_granted_at

    actions
  end

  show do
    tabs do
      tab 'Basic Information' do
        attributes_table title: 'Basic Info' do
          row :id
          row :name
          row :display_name
          row :slug
          row :email
          row :active
          row :access_granted_at
          row :ecommerce_platform
          row :num_products
          row :num_orders
          row :last_updated_categories_at
        end
      end
      tab 'EDI Information' do
        attributes_table title: 'EDI Info' do
          row :internal_vendor_number, hint: 'For EDI Purposes. Auto Generated'
          row :edi_identifier, hint: 'ISA number e.g. ZZ6501487511'
        end
      end

      tab 'Contact Information' do
        attributes_table title: 'Contact Information' do
          row :facebook_url
          row :instagram_url
          row :website
          row :phone_number
        end
      end

      tab 'Shopify Information' do
        attributes_table title: 'Shopify Information' do
          row :shopify_url
          row :shopify_product_unique_identifier
        end
      end

      tab 'DSCO Information' do
        attributes_table title: 'DSCO Information' do
          row :dsco_identifier
        end
      end

      tab 'Instance Properties' do
        attributes_table title: 'Shopify Information' do
          row :instance_type
          row 'Default Markup' do
            number_to_percentage(spree_supplier.default_markup_percentage * 100, precision: 0)
          end
        end
      end

      tab 'Shipping Zones' do
        attributes_table title: 'Shipping Zones' do
          table_for spree_supplier.shipping_zones do
            column :name
            column :description
          end
        end
      end
    end

    panel 'Team Members' do
      table_for spree_supplier.users do
        column :full_name
        column :email
        column :role do |user|
          user.role.name.humanize
        end
        column 'Action' do |user|
          next if user == current_spree_user

          link_to 'impersonate',
                  impersonation_impersonate_path(
                    impersonation_id: user.team_member.internal_identifier
                  ),
                  method: :patch,
                  target: '_blank'
        end
      end
    end

    panel "Import #{'Dsco' if resource.dsco_identifier.present?} Products" do
      render 'download_products'
    end

    panel 'Download Product Images' do
      render 'download_images'
    end

    panel 'Cost / Pricing Import' do
      render 'shopify_csv_import'
    end

    panel 'Upload Size and Color' do
      render 'size_color_upload'
    end

    panel 'Upload Dsco Fulfillments' do
      render 'import_dsco_fulfillments'
    end

    if resource.dsco_identifier.present?
      panel 'MSRP Append - For DSCO Only' do
        render 'dsco_csv_append'
      end
    end

    panel 'Categories Members' do
      table_for spree_supplier.supplier_category_options do |_supplier_category_options|
        column :name
        column :presentation
        column 'Hingeto Supply Master Category', &:platform_category_option
        column 'Action' do |supplier_category_option|
          link_to 'Update',
                  edit_admin_spree_supplier_category_option_path(supplier_category_option),
                  target: '_blank'
        end
      end

      render 'manage_categories'
    end

    panel 'Color Members' do
      table_for spree_supplier.supplier_color_options do |_supplier_color_options|
        column :name
        column :presentation
        column 'Hingeto Supply Master Color', &:platform_color_option
        column 'Action' do |supplier_color_option|
          link_to 'Update',
                  edit_admin_spree_supplier_color_option_path(supplier_color_option),
                  target: '_blank'
        end
      end

      render 'manage_colors'
    end

    panel 'Size Members' do
      table_for spree_supplier.supplier_size_options do |_supplier_size_option|
        column :name
        column :presentation
        column 'Hingeto Supply Master Sizes', &:platform_size_option
        column 'Action' do |supplier_size_option|
          link_to 'Update',
                  edit_admin_spree_supplier_size_option_path(supplier_size_option),
                  target: '_blank'
        end
      end

      render 'manage_sizes'
    end

    panel 'Licenses Members' do
      table_for spree_supplier.supplier_license_options do |_supplier_category_options|
        column :name
        column :presentation
      end
    end

    panel 'Shipping Methods' do
      table_for spree_supplier.shipping_methods do |_shipping_method|
        column :name
        column 'Action' do |shipping_method|
          link_to 'Edit',
                  "/storefront/admin/shipping_methods/#{shipping_method.id}/edit",
                  target: '_blank'
        end
      end

      render 'manage_shipping_methods'
    end

    panel 'Settings/Preferences' do
      render 'settings'
    end

    panel 'Retailer Referrals' do
      table_for Spree::RetailerReferral.where(spree_supplier_id: spree_supplier.id) do
        column :name
        column :url
        column :has_relationship
      end
    end

    active_admin_comments
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :name
      f.input :display_name,
              hint: 'This is the name that will get exported to Shopify and displayed in frontend'\
              'For product exports, it may get overwritten if produc has supplier_brand_name on it'
      f.input :slug
      f.input :email
    end
    f.inputs do
      f.input :instance_type, as: :select,
                              hint: I18n.t('active_admin.hint.instance_type')
      f.input :shopify_product_unique_identifier, as: :select, required: true,
                                                  hint: I18n.t('active_admin.hint.instance_type')
      f.input :default_markup_percentage,
              hint: I18n.t('active_admin.hint.supplier_markup')
    end
    f.inputs do
      f.input :shipping_zones, as: :check_boxes,
                               hint: 'Please only select either US, Canada or ROW for now'
    end
    f.inputs do
      f.input :dsco_identifier, hint: 'Enter this suppliers DSCO identifier'
    end
    f.inputs do
      f.input :edi_identifier, hint: 'EDI Identifier. ISA ID e.g. 129499991263 or ZZ5554443333'
    end
    f.inputs do
      f.input :logo, as: :file, accept: 'images/*'
    end
    f.actions
  end
end
