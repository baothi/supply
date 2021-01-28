Spree::StockItem.class_eval do
  # skip_callback :after_save
  # skip_callback :after_touch
  # skip_callback :after_destroy

  # after_commit :update_listing_quantities, if: :syndication_enabled?

  # check again before saving
  after_commit :saved_stock_item_tracking, if: Proc.new {|row| row.backorderable && row.previous_changes && row.previous_changes[:count_on_hand].present?}

  def syndication_enabled?
    # ENV['SYNDICATE_INVENTORY'] == 'yes'
    false
  end

  def update_listing_quantities
    return unless self.variant.variant_listings.count.positive?

    job = create_long_running_job
    Shopify::SyndicateInventoryWorker.perform_async(job.internal_identifier)
  end

  def saved_stock_item_tracking
    qty_changes = previous_changes[:count_on_hand]
    return unless qty_changes && qty_changes.kind_of?(Array)
    stockitem = (ENV['LOW_STOCK_ITEM']&.to_i || 5)
    changed_of_count_on_hand = qty_changes[1] - qty_changes[0]
    item_tracking = Spree::StockItemTracking.find_or_create_by!(stock_item: self, product: variant.product)

    if qty_changes[0] > stockitem && qty_changes[1] <= stockitem
      item_tracking.update!(state: 'outstock')
    elsif qty_changes[0] <= stockitem && qty_changes[1] > stockitem
      item_tracking.update!(state: 'instock')
    else
      puts("Stock does not change state. Current state: #{item_tracking&.state}")
      return
    end

    product = Spree::Product.where(id: item_tracking.product_id)
    for p in product do
      job = Spree::LongRunningJob.create(action_type: 'import',
                                     job_type: 'email_notification',
                                     initiated_by: 'user',
                                     teamable_type: 'Spree::Retailer',
                                     option_1: p.id,
                                     option_2: item_tracking&.state)
      ::StockItem::SendEmailStockStatusChangedJob.perform_later(job.internal_identifier)
    end

  end

  private

  def create_long_running_job
    Spree::LongRunningJob.create(
      action_type: 'import',
      job_type: 'products_export',
      initiated_by: 'user',
      option_1: self.variant.id
    )
  end
end
