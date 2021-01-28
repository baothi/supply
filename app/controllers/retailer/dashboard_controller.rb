class Retailer::DashboardController < Retailer::BaseController
  # skip_before_action :confirm_access_granted!

  def index
    @products = Spree::Product.all.limit(3)
    set_product_listings
    set_orders
    set_number_variant_stock
  end

  def out_of_stock
    @products = Spree::Product.where(id: out_of_stock_item_trackings)
    @products = search_sort_and_paginate_records(@products)
  end

  def back_in_stock
    @products = Spree::Product.where(id: back_in_stock_item_trackings)
    @products = search_sort_and_paginate_records(@products)
  end

  def deactivated_products
    @products = Spree::Product.where(id: deactivated_products_trackings.select(:product_id))
    @products = search_sort_and_paginate_records(@products)
  end

  def set_product_listings
    @product_listings = Spree::ProductListing.
                        where('retailer_id = :retailer_id',
                              retailer_id: current_retailer.id)
    @added_product = @product_listings.count.positive?
  end

  def set_number_variant_stock
    @out_stock_product_total = out_of_stock_item_trackings.count
    @back_stock_product_total = back_in_stock_item_trackings.count
    @deactivated_products = deactivated_products_trackings.count
  end

  def set_orders
    @orders = Spree::Order.
              where('retailer_id = :retailer_id',
                    retailer_id: current_retailer.id)
    @made_first_sale = @orders.count.positive? ? true : false
    @order_total = @orders.sum(:total)
  end

  def sidebar
    render 'shared/_site-sidebar', layout: false
  end

  private

  def deactivated_products_trackings
    current_retailer.products_discontinued_since(7.days.ago)
  end

  def out_of_stock_item_trackings
    Spree::StockItemTracking.outstock_for_since(current_retailer.id, 7.days.ago).distinct.pluck(:product_id)
  end

  def back_in_stock_item_trackings
    Spree::StockItemTracking.instock_for_since(current_retailer.id, 7.days.ago).distinct.pluck(:product_id)
  end

  def search_sort_and_paginate_records(rows)
    rows = rows.apply_search(params) if params[:search_value].present?
    rows = rows.apply_order(params[:sort]) if params[:sort].present?
    rows.page(params[:page]).per(25)
  end

end
