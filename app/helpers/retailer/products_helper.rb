module Retailer::ProductsHelper
  def shopify_url(product)
    shopify_identifier = get_shopify_id(product)
    return if shopify_identifier.nil?

    "https://#{store_url}/admin/products/#{shopify_identifier}"
  end

  def store_url
    current_retailer.shopify_url
  end

  def get_shopify_id(product)
    product.retailer_listing(current_retailer.id)&.shopify_identifier
  end

  def outer_banner_or_image_placeholder(taxon)
    taxon.outer_banner.exists? ? taxon.outer_banner : image_placeholder
  end

  def image_placeholder
    'noimage/large.png'
  end

  def featured_banner_link(banner)
    taxon_list_smart_link(banner.taxon, banner.internal_identifier)
  end

  def taxon_list_smart_link(taxon, banner_id = nil)
    return '#' if taxon.nil?
    return retailer_list_products_by_license_path(taxon.name) if taxon.license?
    return retailer_list_products_by_category_path(taxon.name) if taxon.category?

    if taxon.custom_collection?
      return retailer_list_products_by_custom_collection_path(
        taxon.name, banner: banner_id
      )
    end
    '#'
  end

  def taxon_or_banner_image(taxon, banner)
    return taxon.inner_banner if taxon.inner_banner.exists?
    return banner.image if banner && banner.image.exists?

    image_placeholder
  end

  def banner_or_taxon_image(banner)
    return banner.image(:large) if banner.image.exists?
    return banner.taxon.inner_banner if banner.taxon && banner.taxon.inner_banner.exists?

    image_placeholder
  end
end
