module Spree::RetailersAndSuppliers::ShopifyCacheable
  extend ActiveSupport::Concern
  include CommitWrap

  def cache_shopify_orders_async!(num_hours: 1)
    begin
      puts "#{I18n.t('orders.cannot_cache_more_than_60_days')}".yellow if num_hours > (60 * 24)
      ActiveRecord::Base.transaction do
        job = Spree::LongRunningJob.create(
          action_type: 'import',
          job_type: 'orders_import',
          initiated_by: 'system',
          option_1: num_hours,
          teamable_type: self.class.to_s,
          teamable_id: self.id
        )

        execute_after_commit do
          Shopify::DownloadAndCacheOrdersWorker.perform_async(job.internal_identifier)
          puts "Successfully queued for #{self.id}:#{self.domain}".green
        end
      end
    rescue => ex
      ErrorService.new(exception: ex).perform
    end
  end

  def cache_shopify_products_async!(num_hours: 1)
    begin
      ActiveRecord::Base.transaction do
        job = Spree::LongRunningJob.create(
          action_type: 'import',
          job_type: 'products_import',
          initiated_by: 'system',
          option_1: num_hours,
          supplier_id: self.id,
          teamable_type: self.class.to_s,
          teamable_id: self.id
        )

        execute_after_commit do
          Shopify::DownloadAndCacheProductsWorker.perform_async(job.internal_identifier)
          puts "Successfully queued for #{self.id}:#{self.domain}".green
        end
      end
    rescue => ex
      ErrorService.new(exception: ex).perform
    end
  end

  def cache_shopify_products_now!(num_hours: 1)
    begin
      ActiveRecord::Base.transaction do
        job = Spree::LongRunningJob.create(
          action_type: 'import',
          job_type: 'products_import',
          initiated_by: 'system',
          option_1: num_hours,
          supplier_id: self.id,
          teamable_type: self.class.to_s,
          teamable_id: self.id
        )

        execute_after_commit do
          Shopify::DownloadAndCacheProductsWorker.new.perform(job.internal_identifier)
          puts "Successfully ran for #{self.id}:#{self.domain}".green
        end
      end
    rescue => ex
      ErrorService.new(exception: ex).perform
    end
  end

  def cache_shopify_events_async!(num_hours: 1)
    begin
      ActiveRecord::Base.transaction do
        job = Spree::LongRunningJob.create(
          action_type: 'import',
          job_type: 'events_import',
          initiated_by: 'system',
          option_1: num_hours,
          option_2: 'Product', # filter
          option_3: 'destroy', # verb
          supplier_id: self.id,
          teamable_type: self.class.to_s,
          teamable_id: self.id
        )

        execute_after_commit do
          Shopify::DownloadAndCacheEventsWorker.perform_async(job.internal_identifier)
          puts "Successfully queued for #{self.id}:#{self.domain}".green
        end
      end
    rescue => ex
      ErrorService.new(exception: ex).perform
    end
  end
end
