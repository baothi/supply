class Retailer::ProductsController < Retailer::BaseController
  before_action :restrict_page_to_hingeto_user,
                only: %i(by_supplier list_by_supplier),
                unless: proc { current_retailer.can_view_supplier_name }

  before_action :set_cards, only: %i(details)
  # before_action :set_supplier_from_variant_or_product
  before_action :set_in_progress_exports
  before_action :set_num_live_products

  # TODO: Move these to configurations
  PER_PAGE = (ENV['PER_PAGE'] || 25).to_i
  MINIMUM_INVENTORY_BUFFER = (ENV['MINIMUM_INVENTORY_BUFFER'] || 5).to_i

  def hydrate
    if params[:product_id]
      product = Spree::Product.find_by_internal_identifier(params[:product_id])
      render json: {
          html_data: render_to_string(partial: 'retailer/products/shared/product',
                                      locals: { product: product })
      }
    else
      render json: { message: 'Please provide an id' }, status: :bad_request
    end
  end

  def index
    license_taxonomy = Spree::Taxonomy.find_by(name: 'License')
    @licenses = nil
    @licenses = license_taxonomy.taxons.where.not(name: 'License').sample(3) if license_taxonomy
    @featured_banners = Spree::FeaturedBanner.all
  end

  # def details
  #   @product = Spree::Product.where(internal_identifier: params[:product_id]).first
  #   @supplier = @product.supplier
  #   @shipping_zones = @product.supplier&.shipping_zones
  # end

  def details
    @product = Spree::Product.where(internal_identifier: params[:product_id]).first
    @supplier = @product&.supplier

    if @product.shopify_product?
      begin
        @cached_product = ShopifyCache::Product.find(id: @product.shopify_identifier.to_i)
      rescue => ex
        ErrorService.new(exception: ex, level: :warning).perform
      end
    end

    if !@product.approved? || !current_retailer.can_access_product?(@product)
      respond_with_insufficient_sales_authority
      return
    end

    @shipping_category = @product.shipping_category
    if @shipping_category.present? && !@shipping_category.shipping_methods.empty?
      # For now let's fetch the first one
      @calculator = @shipping_category.shipping_methods[0].calculator
    end
    @shipping_method = @shipping_category.shipping_methods[0]
    @shipping_zones = @shipping_method&.zones
  end

  def respond_with_insufficient_sales_authority
    respond_to do |format|
      format.js do
        render 'insufficient_sales_authority'
      end

      format.html do
        flash[:alert] = I18n.t 'products.error.insufficient_sales_authority'
        redirect_back(fallback_location: retailer_products_list_path)
      end
    end
  end

  def get_variants
    product = Spree::Product.find_by(internal_identifier: params[:product_id])
    @variants = product.variants if product.present?
  end

  def inventory; end

  def new; end

  def list
    @products = Spree::Product.where(supplier_id: current_retailer.white_listed_suppliers.pluck(:id)).
                              includes([{variants: :stock_items}, :product_listings]).marketplace_compliant_and_approved
    @products = search_sort_and_paginate_products(@products)
  end

  def live
    @products = search_sort_and_paginate_products(live_products)
  end

  def in_progress; end

  def favorites
    @products = current_retailer.favorite_products # TODO: Fetch favourited products
    @products = search_sort_and_paginate_products(@products)
  end

  def add_to_favorites
    product = Spree::Product.find_by(internal_identifier: params[:product_id])
    @favorite = current_retailer.favorites.new(product: product)

    if @favorite.save!
      flash.now[:notice] = 'Added to favorites'
    else
      flash.now[:alert] = 'Could not add to favorites'
    end

    respond_to do |format|
      @selector = params[:product_id]
      format.js { render 'add_to_favorites' }
    end
  end

  def remove_favorite
    begin
      product = Spree::Product.find_by(internal_identifier: params[:product_id])
      @favorite = current_retailer.favorites.find_by(product_id: product.id)
      @favorite.destroy!
      flash.now[:notice] = 'Favorite removed'
    rescue
      flash.now[:alert] = 'Could not remove favorite'
    end

    respond_to do |format|
      @selector = params[:product_id]
      format.js { render 'remove_favorite' }
    end
  end

  def followings
    @licenses = current_retailer.following_licenses
    @categories = current_retailer.following_categories
  end

  def by_supplier
    @suppliers = Spree::Supplier.active.has_permit_selling_authority
  end

  def by_license
    @license_grouping = Spree::Grouping.license
    @license_grouping = @license_grouping.select { |group| group.has_non_zero_taxons_for?(current_retailer) } 
    @featured_banners = Spree::FeaturedBanner.featured_licenses
  end

  def by_license_unassigned
    @license_grouping = Spree::Grouping.license
    @featured_banners = Spree::FeaturedBanner.featured_licenses
  end

  def list_license_by_group
    @group = Spree::Grouping.find_by_slug(params[:slug])
    @taxons = if params[:name] == 'Others'
                Spree::Taxon.other_licenses_not_in_group
              else
                @group.try(:taxons)
              end
    @taxons = @taxons.try(:has_outer_banner) || []
    @taxons = @taxons.select { |taxon| taxon.available_products_for_retailer(current_retailer).count > 0 }
  end

  def by_category
    category_taxonomy = Spree::Taxonomy.find_by(name: 'Plaform Category')
    @categories = category_taxonomy.taxons.where.not(name: 'Platform Category') unless
    category_taxonomy.nil?
  end

  def list_by_supplier
    @supplier = Spree::Supplier.has_permit_selling_authority.find_by(slug: params[:supplier])
    redirect_back(fallback_location: retailer_products_by_supplier_path) if @supplier.nil?
  end

  def list_by_license
    @products = nil
    @license = taxon_for_taxonomy_if_exists?('License', params[:license])
    if @license.nil?
      flash[:alert] = 'Invalid License Selected'
      redirect_back(fallback_location: retailer_products_by_license_path)
    end
    cat_id = params[:cat_id]

    white_listed_products = Spree::Product.
                            where(internal_identifier: current_retailer.white_listed_product_ids).
                            marketplace_compliant_and_approved
    current_retailer.white_listed_suppliers.each do |s|
      white_listed_products = white_listed_products.or(s.products.marketplace_compliant_and_approved)
    end

    product_license_query = white_listed_products.
                            marketplace_compliant_and_approved.
                            with_search_criteria_license_taxon_id(@license.id)
    @categories = product_license_query.pluck("search_attributes->'category_taxons'")
    if cat_id.present?
      product_license_query = product_license_query.with_search_criteria_category_taxon_id(cat_id)
    end
    @products = search_sort_and_paginate_products(product_license_query)
    @products
  end

  def extract_categories; end

  def list_by_category
    @products = nil
    @category = taxon_for_taxonomy_if_exists?('Platform Category', params[:category])
    if @category.nil?
      flash[:alert] = 'Invalid Category Selected'
      redirect_back(fallback_location: retailer_products_by_category_path)
    end
  end

  def list_by_custom_collection
    @products = nil
    @collection = taxon_for_taxonomy_if_exists?('CustomCollection', params[:collection])
    if @collection.nil?
      flash[:alert] = 'Invalid Category Selected'
      redirect_back(fallback_location: retailer_products_by_custom_collection_path)
    end
    @banner = Spree::FeaturedBanner.find_by(internal_identifier: params[:banner])
  end

  def category_for_supplier
    @supplier = Spree::Supplier.find_by(slug: params[:supplier])
    @category = taxon_if_exist(params[:c])
    render :list_by_supplier
  end

  def category_for_license
    @license, @category = get_main_and_child_collection('License', params[:license], params[:c])
    render :list_by_license
  end

  def license_for_category
    @category, @license =
      get_main_and_child_collection('Platform Category', params[:category], params[:l])
    render :list_by_category
  end

  def license_for_custom_collection
    @banner = Spree::FeaturedBanner.find_by(internal_identifier: params[:banner])

    @collection, @license = get_main_and_child_collection(
      'CustomCollection', params[:collection], params[:l]
    )
    render :list_by_custom_collection
  end

  def category_for_custom_collection
    @banner = Spree::FeaturedBanner.find_by(internal_identifier: params[:banner])

    @collection, @category = get_main_and_child_collection(
      'CustomCollection', params[:collection], params[:c]
    )
    render :list_by_custom_collection
  end

  def delete_from_shopify
    job = Spree::LongRunningJob.create(
      action_type: 'export',
      job_type: 'approval',
      initiated_by: 'user',
      retailer_id: @retailer.id,
      teamable_type: 'Spree::Retailer',
      teamable_id: @retailer.id,
      option_1: params[:product_id] # product internal_identifier to delete
    )
    Shopify::ProductShopifyRemovalJob.perform_later(job.internal_identifier)

    flash.now[:notice] = 'Product is being deleted from shopify in background'
    redirect_to :back
  end

  def show
    render 'new'
  end

  def create_addition_job
    Spree::LongRunningJob.create(
      action_type: 'export',
      job_type: 'products_export',
      initiated_by: 'user',
      retailer_id: @retailer.id,
      option_1: params[:product_id] # product ids to download
    )
  end

  def cancel_export
    product = Spree::Product.find_by(internal_identifier: params[:product_id])
    export_process = Spree::ProductExportProcess.find_by(
      retailer: current_retailer,
      product: product
    )

    if export_process.nil? || export_process.updated_less_than_15_minutes_ago?
      flash[:alert] = "We were unable to cancel the export for #{product.name}"
      return redirect_back(fallback_location: retailer_products_list_path)
    end

    export_process.cancel_export!
    flash[:notice] = "#{product.name} is no longer being exported. Please manually "\
      'remove this product from your Shopify account, if it exists.'

    redirect_back(fallback_location: retailer_products_list_path)
  end

  def respond_with_not_marketplace_compliant_issue
    respond_to do |format|
      format.js do
        render 'marketplace_compliance_issue'
      end

      format.html do
        flash.now[:alert] =
          I18n.t 'products.error.compliance_issue'
        redirect_back(
          fallback_location: retailer_product_details_path(@product.internal_identifier)
        )
      end
    end
  end

  def respond_with_default_shopify_location_required
    respond_to do |format|
      format.js do
        render 'shopify_location_required'
      end

      format.html do
        flash.now[:alert] =
          I18n.t 'products.error.shopify_location_required'
        redirect_back(
          fallback_location: retailer_product_details_path(@product.internal_identifier)
        )
      end
    end
  end

  def respond_with_disable_product_addition
    respond_to do |format|
      format.now.js do
        render 'disable_product_addition'
      end

      format.html do
        flash.now[:alert] =
          I18n.t 'products.error.temporarily_disabled'
        redirect_back(
          fallback_location: retailer_product_details_path(@product.internal_identifier)
        )
      end
    end
  end

  def respond_with_ineligible_for_international_stores
    respond_to do |format|
      format.js do
        render 'ineligible_for_international_stores'
      end

      format.html do
        flash.now[:alert] = I18n.t 'products.error.international_retailer'
        redirect_back(
          fallback_location: retailer_product_details_path(@product.internal_identifier)
        )
      end
    end
  end

  def respond_with_successful_product_addition
    respond_to do |format|
      format.js do
        render 'add_to_shopify'
      end

      format.html do
        flash.now[:notice] = I18n.t 'products.success.addition_in_progress'
        redirect_back(
          fallback_location: retailer_product_details_path(@product.internal_identifier)
        )
      end
    end
  end

  def add_to_shopify
    if ENV['ENABLE_ADD_TO_SHOPIFY'] != 'true'
      respond_with_disable_product_addition
      return
    end

    @product = Spree::Product.find_by(internal_identifier: params[:product_id])
    
    if !@product.approved? || !current_retailer.can_access_product?(@product)
      respond_with_insufficient_sales_authority
      return
    end
    
    @product.update_product_compliance_status!

    unless @product.marketplace_compliant?
      respond_with_not_marketplace_compliant_issue
      return
    end

    unless current_retailer.default_location_shopify_identifier.present?
      current_retailer.create_fulfillment_service
      respond_with_default_shopify_location_required
      return
    end

    unless current_retailer.default_location_shopify_identifier.present?
      respond_with_default_shopify_location_required
      return
    end

    unless current_retailer.eligible_to_sell_product?(@product)
      respond_with_ineligible_for_international_stores
      return
    end

    job = create_addition_job

    initiate_export_process(job)

    # flash.now[:notice] = 'Adding Product to Shopify. This can take up to 30 seconds.'

    respond_with_successful_product_addition

    # if export_process.present? && export_process.in_progress?
    #   flash[:alert] = 'An export is already in progress for this product'
    #   return redirect_back(fallback_location: retailer_products_list_path)
    # else
    #   export_process = Spree::ProductExportProcess.find_or_create_by(
    #     retailer: current_retailer,
    #     product: product
    #   )
    #   export_process.reschedule_export! if export_process.completed?
    #   ShopifyExportJob.perform_later(job.internal_identifier)
    # end

    # flash[:notice] = 'Adding Product to Shopify. This can take up to 30 seconds.'
    # redirect_back(fallback_location: retailer_products_list_path)
  end

  def image_upload
    # render text: "Success", status: 200
    render json: {}, status: :ok
  end

  def filtering_params(params)
    params.slice(:search_by)
  end

  def buy_sample
    supplier = Spree::Variant.find_by_internal_identifier(
      params[:variant_id]
    )&.supplier

    supplier_id = supplier&.id

    # raise 'Supplier is required' if supplier_id.nil?

    @order = SampleOrder.new(
      current_retailer.id,
      supplier_id,
      params[:variant_id],
      params[:address_fields]
    ).perform

    respond_to do |format|
      format.js { render 'buy_sample' }
    end
  end

  def download_images
    job = Spree::LongRunningJob.create(
      action_type: 'import',
      job_type: 'shopify_import',
      initiated_by: 'user',
      option_1: params[:product_id]
    )
    Shopify::DownloadProductImageUrlsJob.perform_later(job.internal_identifier)
    flash[:notice] = 'Downloading images from shopify'
    redirect_to retailer_product_details_path(product_id: params[:product_id])
  end

  def sync_images
    product = Spree::Product.find_by(internal_identifier: params[:product_id])
    listing = product.retailer_listing(current_retailer)

    job = Spree::LongRunningJob.create(
      action_type: 'export',
      job_type: 'images_export',
      initiated_by: 'user',
      option_1: listing.internal_identifier
    )

    flash[:notice] = 'Synchronizing images with your store'
    Shopify::SyncImagesJob.perform_later(job.internal_identifier)
    redirect_to retailer_product_details_path(product_id: params[:product_id])
  end

  def resync_product
    product = Spree::Product.find_by(internal_identifier: params[:product_id])
    product.sync_product_in_background!

    flash[:notice] = 'Product is being resynced in the background'
    redirect_to retailer_product_details_path(product_id: product.internal_identifier)
  end

  private

  def live_products
    @live_products = Spree::Product.with_deleted.listed_for_retailer(current_retailer.id)
  end

  def set_num_live_products
    @num_live_products = current_retailer.product_listings.count
  end

  def set_in_progress_exports
    product_export_processes =
      current_retailer.product_export_processes.in_process_of_being_exported

    @export_in_progress_products =
      product_export_processes.updated_less_than_15_minutes_ago

    @export_error_products =
      product_export_processes.updated_more_than_15_minutes_ago

    # Counters
    @export_in_progress_count = @export_in_progress_products.count
    @export_error_count = @export_error_products.count
  end

  def set_cards
    @cards = current_retailer.stripe_cards
    @selected_card = current_retailer.stripe_customer.default_card unless @cards.blank?
  end

  def get_main_and_child_collection(taxonomy, taxon, sub_taxon)
    @products = nil
    taxon = taxon_for_taxonomy_if_exists?(taxonomy, taxon)
    inner_taxon = taxon_if_exist(sub_taxon)

    @products = Spree::Product.in_multiple_taxons(taxon, inner_taxon)
    @products = search_sort_and_paginate_products(@products)

    [taxon, inner_taxon]
  end

  def taxon_for_taxonomy_if_exists?(taxonomy, taxon_slug)
    taxonomy = Spree::Taxonomy.find_by(name: taxonomy)
    taxonomy.taxons.find_by(slug: taxon_slug) if taxonomy
  end

  def taxon_if_exist(taxon_id)
    Spree::Taxon.find_by(id: taxon_id)
  end

  def search_sort_and_paginate_products(products)
    products = products.basic_search(params[:search_value]) if
        params[:search_value].present?
    products = products.with_search_criteria_stock_gte(MINIMUM_INVENTORY_BUFFER) if
        params[:exclude_zero_inventory] == 'yes'
    products = products.with_search_criteria_eligible_for_intl_sale if
        params[:exclude_us_only_product] == 'yes'
    products = products.not_in_retailer_shopify(current_retailer) if
        params[:exclude_shopify_products] == 'yes'
    products = products.with_search_criteria_exclude_discontinued if
        params[:exclude_deactivated_items] == 'yes'
    products = products.apply_order(params[:sort]) if params[:sort].present?
    products.page(params[:page]).per(PER_PAGE)
  end

  def set_supplier_from_variant_or_product
    if params[:variant_id].present?
      @variant = Spree::Variant.find(params[:variant_id])
      @supplier = @variant.supplier
    elsif params[:product_id].present?
      @product = Spree::Product.find(params[:product_id])
      @supplier = @product.supplier
    else
      raise 'Unknown supplier found'
    end
  end

  def initiate_export_process(job)
    # First check product compliance

    @export_process = Spree::ProductExportProcess.find_by(
      retailer: current_retailer,
      product: @product
    )

    if @export_process.present? && @export_process.in_progress?
      flash.now[:alert] = 'An export is already in progress for this product'
    else
      @export_process = Spree::ProductExportProcess.find_or_create_by(
        retailer: current_retailer,
        product: @product
      )
      @export_process.reschedule_export! if @export_process.completed?
      ShopifyExportJob.perform_later(job.internal_identifier)
    end
  end
end
