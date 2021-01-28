class Supplier::SyncController < Supplier::BaseController
  def sync_products
    current_supplier.download_shopify_products!(true)

    notice = 'Your shopify products are being imported.'
    redirect_to supplier_integrations_shopify_path, notice: notice
  end

  def import_collection_products_modal
    current_supplier.init
    @collections = ShopifyAPI::SmartCollection.find(:all, params: { limit: 250 })
  end

  def import_collection_products
    if params[:collection_id]
      job = Spree::LongRunningJob.create(
        action_type: 'import',
        job_type: 'products_import',
        initiated_by: 'user',
        option_1: 'mass',
        option_2: true,
        option_3: { collection_id: params[:collection_id] }.to_json,
        supplier_id: current_supplier.id,
        teamable_type: 'Spree::Supplier',
        teamable_id: current_supplier.id
      )

      Shopify::BulkProductImportWorker.perform_async(job.internal_identifier)
      notice = 'Your Shopify products for the selected collection are being imported.'
    else
      notice = 'No collection is selected'
    end

    redirect_to supplier_integrations_shopify_path, notice: notice
  end

  def disconnect
    creds = current_supplier.shopify_credential
    creds.disable_connection! unless creds.nil?

    redirect_to supplier_integrations_shopify_path,
                alert: 'Removed Shopify. You will no longer be able to bring products or'\
                       'receive orders on your Shopify'
  end
end
