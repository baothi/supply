module Supplier::ProductsHelper
  def panel_status_from_submission(product)
    return 'panel-success' if product.approved?
    return 'panel-danger' if product.declined?

    'panel-warning'
  end
end
