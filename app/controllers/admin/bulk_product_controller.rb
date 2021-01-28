class Admin::BulkProductController < BaseController
  protect_from_forgery with: :exception

  def update_image_counter
    min_id = Spree::Product.minimum(:id)
    max_id = Spree::Product.maximum(:id)
    response = Spree::Product.update_all_image_counters!(min_id, max_id, 500)
    if response
      redirect_to :back, notice: response.message
    else
      redirect_to :back, alert: response.message
    end
  end

  def update_all_product_compliance_status_job
    min_id = Spree::Product.minimum(:id) # Scope to supplier
    max_id = Spree::Product.maximum(:id) # Scope to supplier
    Spree::Product.update_all_cached_compliance_status_info!(min_id, max_id, 500)

    redirect_to :back, notice: 'Cache update in progress. This may take up to 15 minutes'
  end

  def update_product_cache
    job = update_cache_job
    ::Products::ProductCacheRefreshJob.perform_later(job.internal_identifier)
    redirect_to :back, notice: 'Cache update in progress. This may take up to 15 minutes'
  end

  def update_product_categories
    supplier = Spree::Supplier.find_by_slug(params[:id])
    job = update_categories_job(supplier.id)
    ::Category::CategorizeSupplierProductsJob.perform_later(job.internal_identifier)
    redirect_to :back, notice: 'Categories update in progress'
  end

  def map_product_categories
    supplier = Spree::Supplier.find_by_slug(params[:id])
    job = map_categories_job(supplier.id)
    ::Category::MapSupplierProductsJob.perform_later(job.internal_identifier)
    redirect_to :back, notice: 'Mapping update in progress'
  end

  def update_product_colors
    supplier = Spree::Supplier.find_by_slug(params[:id])
    job = update_colors_job(supplier.id)
    ::Color::UpdateSupplierProductsColorsJob.perform_later(job.internal_identifier)
    redirect_to :back, notice: 'Colors are being updated'
  end

  def map_product_colors
    supplier = Spree::Supplier.find_by_slug(params[:id])
    job = update_colors_job(supplier.id)
    ::Color::MapSupplierProductsColorsJob.perform_later(job.internal_identifier)
    redirect_to :back, notice: 'Mapping update in progress'
  end

  # Sizes
  def update_product_sizes
    supplier = Spree::Supplier.find_by_slug(params[:id])
    job = update_colors_job(supplier.id)
    ::Size::UpdateSupplierProductsSizesJob.perform_later(job.internal_identifier)
    redirect_to :back, notice: 'Sizes are being updated'
  end

  def map_product_sizes
    supplier = Spree::Supplier.find_by_slug(params[:id])
    job = update_colors_job(supplier.id)
    ::Size::MapSupplierProductsSizesJob.perform_later(job.internal_identifier)
    redirect_to :back, notice: 'Mapping update for sizes in progress'
  end

  private

  def update_cache_job
    Spree::LongRunningJob.create(
      action_type: 'import',
      job_type: 'products_categorize',
      initiated_by: 'user',
      option_1: 'categorize'
    )
  end

  def update_categories_job(supplier_id)
    Spree::LongRunningJob.create(
      action_type: 'import',
      job_type: 'products_categorize',
      initiated_by: 'user',
      option_1: 'categorize',
      supplier_id: supplier_id
    )
  end

  def update_colors_job(supplier_id)
    Spree::LongRunningJob.create(
      action_type: 'import',
      job_type: 'products_categorize',
      initiated_by: 'user',
      option_1: 'categorize',
      supplier_id: supplier_id
    )
  end

  def map_categories_job(supplier_id)
    Spree::LongRunningJob.create(
      action_type: 'import',
      job_type: 'products_categorize',
      initiated_by: 'user',
      option_1: 'map',
      supplier_id: supplier_id
    )
  end
end
