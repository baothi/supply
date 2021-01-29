SELECT vc.id, sup.id as supplier_id, sup.name AS supplier, vc.sku,
vc.msrp, vc.cost,
vc.minimum_advertised_price
FROM spree_variant_costs AS vc
LEFT join spree_suppliers AS sup on vc.supplier_id = sup.id

