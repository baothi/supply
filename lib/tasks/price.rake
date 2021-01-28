require 'spree'

namespace :price do
  desc 'Copy current variant prices to cost_price'
  task copy_variant_prices_to_cost_price: :environment do
    suppliers = Spree::Supplier.all
    suppliers.each do |supplier|
      job = Spree::LongRunningJob.create(supplier_id: supplier.id,
                                         initiated_by: 'system',
                                         action_type: 'import',
                                         job_type: 'products_import')
      Pricing::SetWholesaleCostJob.perform_later(job.internal_identifier)
    end
  end

  desc 'Set markup price'
  task set_platform_marked_up_prices: :environment do
    suppliers = Spree::Supplier.all
    suppliers.each do |supplier|
      job = Spree::LongRunningJob.create(supplier_id: supplier.id,
                                         initiated_by: 'system',
                                         action_type: 'import',
                                         job_type: 'products_import')
      Pricing::SetMarkupPriceJob.perform_later(job.internal_identifier)
    end
  end
end
