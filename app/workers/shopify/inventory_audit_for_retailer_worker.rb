class Shopify::InventoryAuditForRetailerWorker
  include Sidekiq::Worker
  include CancellableJob

  sidekiq_options queue: 'product_import',
                  backtrace: true,
                  retry: false

  def perform(job_id)
    return if cancelled?

    job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
    job.initialize_and_begin_job! unless job.in_progress?

    @variants_without_listings = []

    begin
      retailer_id = job.retailer_id
      retailer = Spree::Retailer.find(retailer_id)

      return unless retailer.shopify_retailer?

      Axlsx::Package.new do |p|
        p.use_shared_strings = true

        p.workbook.add_worksheet(name: 'Retailer Report') do |sheet|
          # Header Rows
          setup_header_rows(sheet: sheet, retailer: retailer)

          # We wrap each export to try to ensure we continue without issues
          begin
            ShopifyCache::Product.where(
              role: 'retailer',
              shopify_url: retailer.shopify_url
            ).all.each do |retailer_shopify_product|
              # break if cancelled?
              # Iterate through products
              export_variants_from_product_to_rows(
                sheet: sheet,
                retailer_shopify_product: retailer_shopify_product,
                retailer: retailer
              )
            end
          rescue => ex
            job.log_error(ex.to_s)
          end
        end

        p.workbook.add_worksheet(name: 'Variants with missing Listings') do |sheet|
          setup_header_rows_missing_variants(sheet: sheet, retailer: retailer)
          export_missing_variant_listings(
            sheet: sheet,
            variants_without_listings: @variants_without_listings
          )
        end

        # Send Email
        email_audit_file(retailer: retailer, package: p)
      end

      job.mark_job_as_complete!
    rescue => ex
      ErrorService.new(exception: ex).perform
      job.log_error(ex.to_s)
      job.raise_issue!
      return
    end
  end

  def email_audit_file(retailer:, package:)
    # Generate file & attach to job
    file = Tempfile.new(['temporary', '.xlsx'])
    file.binmode
    file.write(package.to_stream.read)
    file.rewind

    OperationsMailer.email_admin_with_attachment(
      subject: "#{DateTime.now.strftime('%m/%d')} Inventory Audit for #{retailer.name}",
      message: 'See attached for the inventory audit.',
      file_path: file.path,
      file_name: "#{retailer.name.parameterize}-audit_file.xlsx"
    ).deliver_now
  end

  def setup_header_rows(sheet:, retailer:)
    grey = sheet.styles.add_style(bg_color: 'A9A9A9', fg_color: '000000')

    sheet.add_row ['Retailer', retailer.name]
    sheet.add_row ['Time of Report', "#{DateTime.now}"]
    sheet.add_row []

    sheet.add_row ['Time Stamp (Added to Retailer Store)',
                   'Product Name',
                   'Retailer SKU',
                   'Retailer - Unfulfilled Quantity in Orders',
                   'Retailer - Inventory @ Shopify',
                   'Retailer - Inventory Management',
                   # Hingeto Application
                   'Hingeto Inventory Count',
                   # 'Hingeto Inventory Count (Legacy)',
                   'Retailer Discrepancy (%)',
                   # Supplier Info
                   'Supplier Name',
                   'Supplier - SKU',
                   'Supplier - Inventory Buffer',
                   'Supplier - Inventory @ Shopify',
                   # Supplier Settings Info
                   'Supplier - Shopify Inventory Policy',
                   'Supplier - Shopify Inventory Management',
                   'Supplier - Published At',
                   'Supplier Discrepancy (%)'], style: grey
  end

  def export_variants_from_product_to_rows(sheet:,
                                           retailer_shopify_product:, retailer:)
    red = sheet.styles.add_style(bg_color: 'FF0000', fg_color: '000000')

    retailer_shopify_product.variants.each do |retailer_shopify_variant|
      # Local Variant
      local_variant = Spree::Variant.locate_hingeto_variant(
        platform_supplier_sku: retailer_shopify_variant.sku
      )
      next unless local_variant.present?

      if local_variant.variant_listings.where(retailer: retailer).empty?
        variants_without_listings_hash = {
            retailer_shopify_variant: retailer_shopify_variant,
            retailer_shopify_product: retailer_shopify_product,
            local_variant: local_variant
        }
        @variants_without_listings << variants_without_listings_hash
      end

      # Supplier
      supplier = local_variant.supplier

      # We only want to show Shopify suppliers for now.
      next unless supplier.shopify_supplier?

      results =
        ShopifyCache::Variant.locate_at_supplier(
          supplier: supplier,
          original_supplier_sku: local_variant.original_supplier_sku,
          include_unpublished: true
        )

      supplier_shopify_variant = results[0]
      supplier_shopify_product = results[1]

      if supplier_shopify_variant.nil? || supplier_shopify_product.nil?
        puts "Issue Finding: #{local_variant.original_supplier_sku} for #{supplier&.name}".red
      end

      # Difference between H2 <> Retailer

      hingeto_quantity =
        Spree::Variant.available_quantity(
          retailer: retailer,
          platform_supplier_sku: retailer_shopify_variant.sku
        )

      retailer_discrepancy = calculate_retailer_discrepancy(
        retailer_shopify_variant: retailer_shopify_variant,
        hingeto_quantity: hingeto_quantity
      )

      # Difference between H2 <> Supplier
      supplier_discrepancy = calculate_supplier_discrepancy(
        supplier_shopify_variant: supplier_shopify_variant,
        supplier_shopify_product: supplier_shopify_product,
        supplier_buffer: supplier&.setting_inventory_buffer.to_i,
        hingeto_quantity: hingeto_quantity
      )

      style = nil
      if retailer_discrepancy.is_a?(Float)
        style = red if retailer_discrepancy > 25
      end

      if supplier_discrepancy.is_a?(Float)
        style = red if supplier_discrepancy > 25
      end

      # Add Row to Sheet
      add_row_to_sheet(sheet: sheet,
                       supplier: supplier,
                       retailer: retailer,
                       local_variant: local_variant,
                       hingeto_quantity: hingeto_quantity,
                       supplier_shopify_product: supplier_shopify_product,
                       supplier_shopify_variant: supplier_shopify_variant,
                       retailer_shopify_product: retailer_shopify_product,
                       retailer_shopify_variant: retailer_shopify_variant,
                       retailer_discrepancy: retailer_discrepancy,
                       supplier_discrepancy: supplier_discrepancy,
                       style: style)
    end
  end

  def add_row_to_sheet(sheet:,
                       supplier:,
                       retailer:,
                       local_variant:,
                       hingeto_quantity:,
                       supplier_shopify_product:,
                       supplier_shopify_variant:,
                       retailer_shopify_product:,
                       retailer_shopify_variant:,
                       retailer_discrepancy:,
                       supplier_discrepancy:,
                       style:)
    unfulfilled_quantity =
      ShopifyCache::Order.quantity_of_items_in_orders_at_retailer_store(
        platform_supplier_sku: retailer_shopify_variant.sku,
        retailer: retailer
      )

    sheet.add_row ["#{retailer_shopify_variant.created_at}",
                   retailer_shopify_product.title,
                   retailer_shopify_variant.sku,
                   unfulfilled_quantity,
                   retailer_shopify_variant.inventory_quantity,
                   retailer_shopify_variant.inventory_management,
                   # Hingeto
                   hingeto_quantity,
                   "#{retailer_discrepancy}",
                   # local_variant&.legacy_available_quantity,
                   # Supplier
                   supplier&.name,
                   local_variant.original_supplier_sku,
                   supplier&.setting_inventory_buffer,
                   supplier_shopify_variant&.inventory_quantity,
                   # Supplier Settings
                   supplier_shopify_variant&.inventory_policy,
                   supplier_shopify_variant&.inventory_management,
                   supplier_shopify_product&.published_at,
                   "#{supplier_discrepancy}"], style: style
  end

  def calculate_retailer_discrepancy(retailer_shopify_variant:,
                                     hingeto_quantity:)
    retailer_quantity = retailer_shopify_variant&.inventory_quantity.to_i
    # local_quantity = local_variant&.available_quantity.to_i

    return 0 if retailer_quantity.zero? && hingeto_quantity.zero?
    return 'Out of Stock @ Retailer' if retailer_quantity.zero?
    return 'Negative Stock @ Retailer' if retailer_quantity.negative?

    difference = (retailer_quantity - hingeto_quantity).abs
    discrepancy = ((difference / retailer_quantity.to_f) * 100)
    discrepancy.to_f
  end

  def calculate_supplier_discrepancy(supplier_shopify_variant:,
                                     supplier_shopify_product:,
                                     supplier_buffer:,
                                     hingeto_quantity:)

    return 'N/A' if supplier_shopify_variant.nil?
    return 'Unlimited Stock @ Supplier' if supplier_shopify_variant.do_not_track_inventory?
    return 'Unpublished @ Supplier' if supplier_shopify_product.published_at.nil?

    supplier_quantity = (supplier_shopify_variant.inventory_quantity.to_i - supplier_buffer.to_i)
    # local_quantity = local_variant&.available_quantity.to_i

    return 'Out of Stock @ Supplier' if supplier_quantity.zero? || supplier_quantity.negative?

    difference = (supplier_quantity - hingeto_quantity).abs
    discrepancy = ((difference / supplier_quantity.to_f) * 100)
    discrepancy.to_f
  end

  def setup_header_rows_missing_variants(sheet:, retailer:)
    grey = sheet.styles.add_style(bg_color: 'A9A9A9', fg_color: '000000')

    sheet.add_row ['Retailer', retailer.name]
    sheet.add_row ['Time of Report', "#{DateTime.now}"]
    sheet.add_row []

    sheet.add_row ['Time Stamp (Added to Retailer Store)',
                   'Product Name',
                   'Retailer SKU',
                   'Retailer - Inventory @ Shopify'], style: grey
  end

  def export_missing_variant_listings(sheet:, variants_without_listings:)
    variants_without_listings.each do |variant|
      retailer_shopify_variant = variant[:retailer_shopify_variant]
      retailer_shopify_product = variant[:retailer_shopify_product]

      sheet.add_row ["#{retailer_shopify_variant.created_at}",
                     retailer_shopify_product.title,
                     retailer_shopify_variant.sku,
                     retailer_shopify_variant.inventory_quantity]
    end
  end
end
