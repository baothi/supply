ActiveAdmin.register Spree::Product do
  # config.filters = false
  config.per_page = 10

  scope :not_discontinued_and_pending_review

  scope :not_discontinued_and_pending_review_with_images
  scope :not_discontinued_and_pending_review_without_images

  scope :not_discontinued
  scope :approved
  scope :pending_review
  scope :declined

  scope :marketplace_compliant
  scope :submission_compliant
  scope :marketplace_compliant_and_approved
  scope :marketplace_compliant_and_pending_review

  filter :name,  as: :string
  filter :internal_identifier, as: :string
  filter :license_name, as: :string
  filter :supplier

  # The sub brand that suppliers is selling
  # TODO: Change to be powered by Spree::Brand (new model)

  filter :supplier_brand_name
  filter :image_counter
  filter :submission_state
  filter :variant_original_supplier_sku_is, label: 'Original Supplier SKU', as: :string

  actions :all, except: [:destroy]

  menu id: 'products', label: 'Products', priority: 3

  permit_params :shipping_category_id, :license_name,
                :shopify_vendor, :shopify_product_type,
                :supplier_id

  collection_action :process_sole_society_products, method: :post do
    long_running_job_params = params[:long_running_job]

    file = long_running_job_params.try(:fetch, :file)

    if long_running_job_params.blank? || file.blank?
      redirect_back fallback_location: admin_data_import_export_statuses_path,
                    alert: 'File is required.'
      return
    end

    supplier = Spree::Supplier.find(ENV['SOLE_SOCIETY_INTERNAL_SUPPLIER_ID'].to_i)

    puts "Processing with Supplier: #{supplier.name}".yellow

    # Create Long Running Job
    job = Spree::LongRunningJob.create(
      action_type: 'import',
      job_type: 'products_import',
      initiated_by: 'user',
      supplier_id: supplier.id,
      input_csv_file: file
    )

    job.save!

    puts "Created JOB #{job.internal_identifier} for Docs".blue

    SoleSociety::ProductImportJob.perform_later(job.internal_identifier)

    redirect_back fallback_location: admin_data_import_export_statuses_path,
                  notice: 'File Processing in Place.'
  end

  collection_action :process_sole_society_images, method: :post do
    long_running_job_params = params[:long_running_job]

    file = long_running_job_params.try(:fetch, :file)

    if long_running_job_params.blank? || file.blank?
      redirect_back fallback_location: admin_data_import_export_statuses_path,
                    alert: 'File is required.'
      return
    end

    supplier = Spree::Supplier.find(ENV['SOLE_SOCIETY_INTERNAL_SUPPLIER_ID'].to_i)

    puts "Processing with Supplier: #{supplier.name}".yellow

    # Create Long Running Job
    job = Spree::LongRunningJob.create(
      action_type: 'import',
      job_type: 'images_import',
      initiated_by: 'user',
      supplier_id: supplier.id,
      input_csv_file: file
    )

    job.save!

    puts "Created JOB #{job.internal_identifier} for Docs".blue

    Csv::Import::SoleSociety::ImageImportWorker.perform_async(job.internal_identifier)

    redirect_back fallback_location: admin_data_import_export_statuses_path,
                  notice: 'File Processing in Place.'
  end

  controller do
    include CommitWrap

    def scoped_collection
      # super.includes({ variants: :prices, }, :shipping_category, :taxons)
      super.includes(
        :master,
        :variants_including_master,
        :variant_images,
        :supplier,
        {
            taxons: [:taxonomy]
        },
        {
            variants:
                [
                    :images,
                    {
                        supplier:
                        [:shopify_credential]
                    },
                    :prices,
                    :stock_items,
                    :product
                ]
        },
        shipping_category: [:shipping_methods]
      )
      # includes( { bees: [ { cees: [:ees, :effs] }, :dees] }, :zees)
    end

    def find_resource
      scoped_collection.where(slug: params[:id]).first!
    end

    # For some reason, I am needing to add this to ActiveAdmin for us
    # otherwise udpates aren't properly working
    def update
      # puts permitted_params.inspect
      resource.update(permitted_params[:product])
      # resource.update(permitted_params)
      redirect_to resource_path(resource), notice: 'Successfully updated!'
    end

    def permitted_params
      params.permit(product:
                        %i(shipping_category_id
                           description
                           platform_category_option_id
                           supplier_category_option_id
                           name
                           shopify_vendor
                           supplier_product_type))
    end

    def create_product_update_job(supplier_id, shopify_ids)
      ActiveRecord::Base.transaction do
        job = Spree::LongRunningJob.create(
          action_type: 'import',
          job_type: 'products_import',
          initiated_by: 'user',
          option_4: shopify_ids.join(','),
          supplier_id: supplier_id
        )

        execute_after_commit do
          Shopify::ProductUpdateWorker.perform_async(job.internal_identifier)
        end
      end
    end

    ###
    # Create Multiple Jobs to download these images
    ##
    def create_multiple_product_image_download_job(product_ids)
      product_ids.each do |product_id|
        ActiveRecord::Base.transaction do
          job = Spree::LongRunningJob.create(
            action_type: 'import',
            job_type: 'images_import',
            initiated_by: 'user',
            option_1: product_id
          )

          execute_after_commit do
            Shopify::Image::SingleImportJob.perform_later(job.internal_identifier)
          end
        end
      end
    end

    def create_product_approval_job(product_ids)
      job = Spree::LongRunningJob.create(
        action_type: 'import',
        job_type: 'products_import',
        initiated_by: 'user',
        option_4: product_ids.join(',')
      )

      ProductsApprovalJob.perform_later(job.internal_identifier)
    end

    def delete_bulk_products_job(product_ids)
      job = Spree::LongRunningJob.create(
        action_type: 'import',
        job_type: 'products_import',
        initiated_by: 'user',
        option_4: product_ids.join(',')
      )

      ProductsDeletionJob.perform_later(job.internal_identifier)
    end

    def run_compliance_check_job(product_ids)
      job = Spree::LongRunningJob.create(
        action_type: 'import',
        job_type: 'products_import',
        initiated_by: 'user',
        option_4: product_ids.join(',')
      )

      ProductsComplianceCheckJob.perform_later(job.internal_identifier)
    end
  end

  action_item :index, only: :index do
    link_to 'Export All As CSV', export_csv_path(klass_name: resource_class.name, columns: %i(
id name description num_product_listings submission_state num_variants supplier_name stock_quantity
eligible_for_international_sale
))
  end

  action_item :update_image_counters, only: :index do
    link_to 'Update Image Counters', update_image_counter_path
  end

  action_item :update_product_cache, only: :index do
    link_to 'Update Products Cache', update_product_cache_path
  end

  batch_action :resync_from_shopify do |ids|
    selected_products = batch_action_collection.find(ids)
    grouped_selected_products = selected_products.group_by(&:supplier_id)

    grouped_selected_products.each do |supplier_id, supplier_products|
      shopify_ids = supplier_products.pluck(:shopify_identifier)
      create_product_update_job(supplier_id, shopify_ids)
    end

    redirect_back fallback_location: collection_path,
                  notice: 'Products are being resynced in the background'
  end

  batch_action :approve do |ids|
    create_product_approval_job(ids)

    redirect_back fallback_location: collection_path,
                  notice: 'Products are being approved in the background'
  end

  batch_action :download_latest_images_for_ids do |ids|
    create_multiple_product_image_download_job(ids)
    redirect_back fallback_location: collection_path,
                  notice: 'Images for the selected products are being downloaded in the background'
  end

  batch_action :delete_product_ids, confirm: 'Are you sure?' do |ids|
    delete_bulk_products_job(ids)

    redirect_back fallback_location: collection_path,
                  notice: 'Products are being deleted in the background'
  end

  batch_action :run_compliance_check do |ids|
    run_compliance_check_job(ids)
    redirect_back fallback_location: collection_path,
                  notice: 'Products compliance check is running in the background, check back later'
  end

  member_action :update_preferences, method: :post do
    params[:product][:settings].each do |key, value|
      resource.set_setting(key, value)
    end
    resource.save
    redirect_to resource_path(resource), notice: 'Successfully updated!'
  end

  member_action :crop_image, method: :post do
    product = Spree::Product.find_by_slug(params[:id])
    image = Spree::Image.find(params[:image_id])
    image.upload_2_cloudinary!
    redirect_to resource_path(product), notice: 'Image Cropped Successfully'
  end

  index download_links: [:csv_email], pagination_total: false do
    selectable_column

    column :name do |product|
      div class: 'popover__wrapper' do
        h3 do
          link_to product.name, admin_spree_product_path(product)
        end
        div class: 'popover__content' do
          table_for product.variants.limit(5), class: 'cool-table'  do
            column :original_supplier_sku
            column :platform_supplier_sku
            column :master_msrp
            column :master_cost
            column :price
            column :discontinue_on
            column :supplier_color_value
            column :supplier_size_value
            # column :available_quantity
          end
        end
      end
    end

    column 'Product Status', :submission_state
    column 'Compliant', :submission_compliant
    column 'Availability' do |product|
      product.discontinue_on || 'Active'
    end
    column 'Vendor' do |product|
      product.supplier_brand_name || product.supplier.display_name
    end
    column 'Image' do |product|
      variant_master = product.master
      return if variant_master.nil?

      image = variant_master.active_admin_mini_image
      link_to image_tag(image), admin_spree_product_path(product) unless image.nil?
    end
    column 'Category' do |product|
      product.category || 'n/a'
    end
    # column 'Pricing' do |product|
    #   table_for :pricing do
    #     column 'MSRP' do
    #       product.msrp_price
    #     end
    #     column 'Cost' do
    #       product.price
    #     end
    #   end
    # end
    column 'Shipping Rates' do |product|
      table_for :shipping_rates do
        calculator = product.shipping_method&.calculator
        if calculator.nil?
          "Shipping method  for product doesn't have a calculator"
        else
          column 'US' do
            if calculator.preferences[:first_item_us].try(:positive?)
              "#{calculator.preferences[:first_item_us]} \
              (#{calculator.preferences[:additional_item_us]})"
            else
              'n/a'
            end
          end

          column 'CA' do
            if calculator.preferences[:first_item_canada].try(:positive?)
              "#{calculator.preferences[:first_item_canada]} \
              (#{calculator.preferences[:additional_item_canada]})"
            else
              'n/a'
            end
          end

          column 'ROW' do
            if calculator.preferences[:first_item_rest_of_world].try(:positive?)
              "#{calculator.preferences[:first_item_rest_of_world]} \
              (#{calculator.preferences[:first_item_rest_of_world]})"
            else
              'n/a'
            end
          end
        end
      end
    end
    column 'Variants' do |product|
      link_to "#{product.variants.count} \
              (#{product.variants.not_discontinued_and_submission_compliant.count})",
              admin_spree_variants_path(q: { product_id_equals: product.id })
    end
    # column 'Inventory' do |product|
    #   product.variants.not_discontinued_and_submission_compliant.
    #     map(&:count_on_hand).reduce(0) { |sum, i| sum + i }
    # end

    actions
  end

  action_item :reject_product, only: :show do
    link_to 'Reject Product', action: :reject_product unless spree_product.declined?
  end

  action_item :approve_product, only: :show do
    link_to 'Approve Product', action: :approve_product unless spree_product.approved?
  end

  action_item :update_compliance, only: :show do
    link_to 'Run Compliance Check', action: :update_compliance
  end

  action_item :create_size_color, only: :show, if: proc { resource.default_variant_product? } do
    link_to 'Create One Size and Color', action: :create_default_option_values
  end

  # Member Actions

  member_action :download_latest_images, method: :get do
    resource.download_shopify_product_images!
    redirect_to :back, alert: 'Downloading images in background!'
  end

  member_action :reject_product, method: :get do
    begin
      resource.skip_middle_steps_and_reject!
      redirect_to :back, alert: 'Rejected Product!'
    rescue => ex
      puts "#{ex}".red
      redirect_to :back, alert: "#{ex}: #{resource&.errors&.full_messages&.join('. ')}"
      return
    end
  end

  member_action :approve_product, method: :get do
    begin
      resource.skip_middle_steps_and_approve!
      redirect_to :back, notice: 'Approved Product!'
      return
    rescue => ex
      puts "#{ex}".red
      redirect_to :back, alert: "#{ex}: #{resource&.errors&.full_messages&.join('. ')}"
      return
    end
  end

  member_action :update_compliance, method: :get do
    # Simply Touching will force a compliance refresh
    resource.refresh_compliance_now!
    redirect_to resource_path(resource),
                notice: 'Successfully Updated Compliance'
  end

  member_action :create_default_option_values, method: :get do
    # Simply Touching will force a compliance refresh
    resource.convert_default_title_to_color_size
    resource.set_approximate_size_based_on_option_type!
    resource.create_supplier_size_options_from_existing_values!
    resource.set_approximate_color_based_on_option_type!
    resource.create_supplier_color_options_from_existing_values!

    redirect_to resource_path(resource),
                notice: 'Successfully Created One Size and Multi Color'
  end

  form do |f|
    f.semantic_errors

    inputs do
      # input :tax_category
      input :shipping_category
      input :supplier
      input :name
      input :description
      input :available_on
      input :discontinue_on
      # input :slug
      # input :meta_description
      # input :meta_keywords
      # input :meta_title
      input :image_urls, hint: 'Please do not edit this unless you are on the engineering team'
      # input :shopify_vendor
      # input :license_name
      input :shopify_product_type
    end

    inputs do
      input :supplier_product_type
      input :supplier_category_option
      input :platform_category_option
    end

    actions
  end

  show do
    attributes_table title: 'Basic Details' do
      row :eligible_for_approval?
      row :eligibility_reasoning
      row :id
      row :internal_identifier
      row :supplier
      row :supplier_brand_name
      row :name

      row :description
      row :available_on
      row :discontinue_on
      row :deleted_at
      row 'Listings' do |product|
        link_to product.product_listings.count,
                admin_spree_product_listings_path(
                  q: { product_id_equals: product.id }
                )
      end
      row 'Variants' do |product|
        link_to product.variants.count,
                admin_spree_variants_path(q: { product_id_equals: product.id })
      end
      row :slug
      row :shipping_category
      row :created_at
      row :updated_at
      row :submission_state
    end

    attributes_table title: 'Category Information' do
      row :supplier_product_type
      row :supplier_category_option
      row :platform_category_option
    end

    attributes_table title: 'Compliance Information' do
      row :submission_compliant
      row :submission_compliance_log
      row :submission_compliance_status_updated_at
      # Market
      row :marketplace_compliant
      row :marketplace_compliance_log
      row :marketplace_compliance_status_updated_at
    end

    panel 'Settings/Preferences' do
      render 'settings'
    end

    attributes_table title: 'Image Information' do
      row :image_counter,
          hint: 'Keep in mind this value was last updated at the below time'
      row :last_updated_image_counter_at
    end

    attributes_table title: 'Shopify Details' do
      row :image_urls
      row :shopify_identifier
      row :shopify_vendor
      row :license_name
      row :shopify_product_type
    end

    attributes_table title: 'Images' do
      spree_product.images.each do |img|
        columns do
          column do
            image_tag(img&.attachment&.url(:large))
          end
          column do
            button_to 'Crop Image', crop_image_admin_spree_product_path,
                      data: { confirm: 'Are you sure', disable_with: 'Cropping...' },
                      params: { image_id: img.id }
          end
        end
      end
    end

    panel 'Variants' do
      table_for resource.variants do
        column :original_supplier_sku do |v|
          link_to v.original_supplier_sku,
                  admin_spree_variant_path(v)
        end
        column :platform_supplier_sku
        column :master_cost
        column :master_msrp
        column :master_map
        column :discontinue_on
        column :available_quantity
        column :supplier_color_value
        column :supplier_size_value
        # column :platform_color_option
        # column :platform_size_option
        column :submission_compliant
        # column :second_option_value
        # column :third_option_value
      end
    end

    panel 'Settings/Preferences' do
      render 'settings'
    end
  end
end
