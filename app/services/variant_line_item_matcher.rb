class VariantLineItemMatcher
  attr_accessor :retailer, :supplier, :shopify_line_item
  def initialize(shopify_line_item, retailer)
    @retailer = retailer
    @shopify_line_item = shopify_line_item

    # @supplier = @line_item.variant&.supplier

    # raise 'Supplier is required' if @supplier.nil?
  end

  def perform
    # first find variant using listing
    begin
      variant_listing =
        Spree::VariantListing.find_by(shopify_identifier: shopify_line_item.variant_id)
      variant = variant_listing.variant if variant_listing.present?

      return variant if variant

      # next find using barcode and sku
      variant_with_other_properties(shopify_line_item)
    rescue => e
      puts e
      nil
    end
  end

  def variant_with_other_properties(shopify_line_item)
    puts "Retailer Variant SKU: #{shopify_line_item.sku}".yellow
    puts "Retailer Variant ID: #{shopify_line_item.variant_id}".yellow

    barcode = nil

    supplier_sku = shopify_line_item.sku
    retailer_variant_id = shopify_line_item.variant_id

    unless retailer_variant_id.nil?
      shopify_variant = retrieve_shopify_variant_from_retailer(retailer_variant_id)
      barcode = shopify_variant.barcode unless shopify_variant.nil?
    end

    options = {}
    options[:barcode] = barcode
    options[:supplier_sku] = supplier_sku

    # find using sku and barcode
    results = get_variants_with_barcode_and_sku(options)
    return results.first if results.count == 1

    # find using line item name before going to supplier store
    variant = get_variant_with_line_item_name(shopify_line_item, results)
    return variant if variant.present?

    # go to supplier shopify to verify variant when multiple variants are found
    variant = return_eligible_variant(results)
    variant
  end

  def retrieve_shopify_variant_from_retailer(retailer_variant_id)
    begin
      retailer.initialize_shopify_session!
      shopify_variant = CommerceEngine::Shopify::Variant.find(retailer_variant_id)
      retailer.destroy_shopify_session!
      return shopify_variant
    rescue
      nil
    end
  end

  def get_variants_with_barcode_and_sku(options)
    # search for variant using barcode and sku
    begin
      table = Spree::Variant.arel_table
      barcode = options[:barcode]
      supplier_sku = options[:supplier_sku]&.upcase

      if barcode.present?
        puts 'Searching with barcode alone'.yellow unless Rails.env.test?
        results = Spree::Variant.not_discontinued.where(table[:barcode].eq(barcode))
      elsif supplier_sku.present?
        puts 'Searching with SKU alone'.yellow unless Rails.env.test?
        results = Spree::Variant.not_discontinued.where(
          table[:platform_supplier_sku].eq(supplier_sku)
        )
      end
      # return variant if only one variant is found
      return results
    rescue => ex
      puts "#{ex}".red
      # send mail notifying retailer about line item that couldnt be paired
      nil
    end
  end

  def return_eligible_variant(results)
    return nil unless results.present?

    eligible_variants = []

    results.each do |variant|
      begin
        next if variant.shopify_identifier.nil?

        search_results = ShopifyCache::Variant.locate_at_supplier(
          supplier: variant.supplier,
          original_supplier_sku: variant.original_supplier_sku
        )

        supplier_shopify_variant = search_results[0]
        eligible_variants << variant if supplier_shopify_variant.present?
      rescue => ex
        puts "Was unable to find: #{variant.shopify_identifier} in Shopify Cache: #{ex}".yellow
        puts "#{ex.backtrace}".yellow
      end
    end

    # return nil if multiple variants are returned or return variant if only one is found
    # TODO: Re-evaluate this logic
    eligible_variants.count == 1 ? eligible_variants.first : nil
  end

  def get_variant_with_line_item_name(shopify_line_item, results)
    return nil unless results.present?

    variants = []
    results.each do |variant|
      variant_name = variant.name
      variant_options_title = variant.option_values_by_order.join(' / ')
      if shopify_line_item.title == variant_name &&
         shopify_line_item.variant_title == variant_options_title
        variants << variant
      end
    end
    variants.count == 1 ? variants.first : nil
  end
end
