SELECT p.id, sup.id as supplier_id, sup.name AS supplier, p.name AS product_title, p.description, 
p.shopify_vendor, p.supplier_brand_name,
p.vendor_style_identifier, v.sku, v.original_supplier_sku, v.barcode, v.gtin, 
v.weight, v.weight_unit, v.height, 
v.supplier_color_value AS supplier_color, spco.name AS hingeto_color,
v.supplier_size_value AS supplier_size, spso.name AS hingeto_size,
v.supplier_category_value AS supplier_category, spcao.name AS hingeto_category,
array_to_string(v.image_urls, ',' ) AS variant_image, array_to_string(p.image_urls, ',' ) AS product_image,
v.cost_price as wholesale_cost, v.cost_currency, v.msrp_price, v.msrp_currency, v.map_price, p.submission_state
FROM spree_products AS p
LEFT join spree_variants AS v on p.id = v.product_id
LEFT join spree_suppliers AS sup on p.supplier_id = sup.id
LEFT join spree_platform_color_options  AS spco on v.platform_color_option_id = spco.id
LEFT join spree_platform_size_options  AS spso on v.platform_size_option_id = spso.id
LEFT join spree_platform_category_options AS spcao on p.platform_category_option_id = spcao.id
