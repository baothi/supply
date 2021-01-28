module Retailer::OrdersHelper
  def card_logo(brand)
    case brand
    when 'Visa'
      'fa fa-cc-visa'
    when 'American Express'
      'fa fa-cc-amex'
    when 'MasterCard'
      'fa fa-cc-mastercard'
    when 'Discover'
      'fa fa-cc-discover'
    else
      'fa fa-cc-credit-card'
    end
  end

  def address_full(address)
    "#{address.city}, #{address.name_of_state}, #{address.zipcode}, #{address.country_name}"
  end

  def tag_class(status)
    status ? 'tag-success' : 'tag-danger'
  end

  def shipping_status_tag_class(shipping_status)
    shipping_status = case shipping_status
                      when 'pending'
                        'tag-warning'
                      when 'canceled'
                        'tag-danger'
                      when 'ready'
                        'tag-danger'
                      when 'partial'
                        'tag-warning'
                      when 'shipped'
                        'tag-success'
                      else
                        'tag-danger'
                      end
    shipping_status
  end

  def translate_to_shopify_shipping_status(status)
    shipping_status = case status
                      when 'pending', 'ready'
                        'Unfulfilled'
                      when 'partial'
                        'Partially Fulfilled or Canceled'
                      when 'shipped'
                        'Fulfilled'
                      when 'canceled'
                        'Canceled'
                      else
                        'Unfulfilled'
                      end
    shipping_status
  end

  # Blocking Helper
  def variants_from_barcode(retailer_variant_sku, retailer_variant_id, retailer, supplier)
    puts "Retailer Variant SKU: #{retailer_variant_sku}".yellow
    puts "Retailer Variant ID: #{retailer_variant_id}".yellow

    barcode = nil

    supplier_sku = retailer_variant_sku

    unless retailer_variant_id.nil?
      shopify_variant = retrieve_shopify_variant_from_retailer(retailer, retailer_variant_id)
      barcode = shopify_variant.barcode unless shopify_variant.nil?
    end

    return [] if barcode.nil? && supplier_sku.nil?

    options = {}
    options[:barcode] = barcode unless barcode.nil?
    options[:supplier_sku] = supplier_sku unless supplier_sku.nil?

    variants = return_eligible_variants(supplier, options)
    variants
  end

  def retrieve_shopify_variant_from_retailer(retailer, retailer_variant_id)
    begin
      retailer.initialize_shopify_session!
      shopify_variant = CommerceEngine::Shopify::Variant.find(retailer_variant_id)
      retailer.destroy_shopify_session!
      return shopify_variant
    rescue
      nil
    end
  end

  def build_query_for_barcode_and_supplier_sku(barcode, supplier_sku)
    table = Spree::Variant.arel_table

    if barcode.present? && supplier_sku.present?
      puts 'Searching with barcode & SKU'.yellow
      results = Spree::Variant.where(
        table[:barcode].eq(barcode).
            or(table[:platform_supplier_sku].eq(supplier_sku))
      )
    elsif barcode.present?
      puts 'Searching with barcode alone'.yellow
      results = Spree::Variant.where(table[:barcode].eq(barcode))
    elsif supplier_sku.present?
      puts 'Searching with SKU alone'.yellow
      results = Spree::Variant.where(table[:platform_supplier_sku].eq(supplier_sku))
    end
    results
  end

  def return_eligible_variants(supplier, options)
    eligible_variants = []
    begin
      barcode = options[:barcode]
      supplier_sku = options[:supplier_sku]

      results = build_query_for_barcode_and_supplier_sku(barcode, supplier_sku)

      results.each do |variant|
        begin
          next if variant.shopify_identifier.nil?

          search_results = ShopifyCache::Variant.locate_at_supplier(
            supplier: supplier,
            original_supplier_sku: variant.original_supplier_sku
          )

          supplier_shopify_variant = search_results[0]

          eligible_variants << variant if supplier_shopify_variant.present?
        rescue => ex
          puts "Was unable to find: #{variant.shopify_identifier} at Shopfiy: #{ex}".yellow
        end
      end
    rescue => ex
      puts "#{ex}".red
      eligible_variants = []
    end
    eligible_variants
  end

  def line_report(status, text)
    if status
      "<div class='checkbox-custom checkbox-success'>
        <input type='checkbox' checked=''>
        <label>#{text}</label>
      "
    else
      "<div>
        <i class='fa fa-times report-error'></i>
        <label style='margin-bottom: 0;''>#{text}</label>
      "
    end
  end

  def shopify_order_url(order_id, retailer)
    store_url = retailer.shopify_url
    "https://#{store_url}/admin/orders/#{order_id}"
  end
end
