class Shopify::UpdateComplianceWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker

  sidekiq_options queue: 'product_import',
                  backtrace: true,
                  retry: 5

  # Works with variants and products
  def perform(klass, klass_id)
    instance = klass.constantize.find(klass_id)
    begin
      instance.update_product_compliance_status!
    rescue => ex
      puts ex.to_s.red
      puts ex.backtrace.to_s.red
      Rollbar.error(ex, product_id: product_id)
      return
    end
  end
end
