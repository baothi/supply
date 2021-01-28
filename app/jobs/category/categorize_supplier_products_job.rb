class Category::CategorizeSupplierProductsJob < ApplicationJob
  include Emailable

  queue_as :default

  def perform(job_id)
    job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
    job.initialize_and_begin_job! unless job.in_progress?

    supplier = Spree::Supplier.find_by(id: job.supplier_id)
    # Number of suppliers, since we have no plans to iterate through
    # all the products directly.. just the unique number of categories

    job.update(total_num_of_records: 1)

    begin
      # This creates & assigns all the shipping / supplier category options & more.
      supplier.create_categories_and_shipping_info_from_shopify_product_type!

      # This will clear out any Taxons on the Product and add the latest matched version
      supplier.assign_supplier_products_to_platform_category_options!

      # Count number of categories created
      categories =
        Spree::SupplierCategoryOption.where("created_at > '#{job.time_started}'")
      category_count = categories.count

      subject = "[Category Mapping] Created #{category_count} categories"
      body =
        "The platform has created #{category_count} supplier categories "\
        "for #{supplier.name}.<br><br>"\
        "They are: #{categories.map(&:name).join(',')}<br><br>"\
        'Please login to ensure that all looks good & map these bad boys!'

      email_results_to_operations!(subject, body)
    rescue => ex
      puts "#{ex}".red
      puts "#{ex.backtrace}".red

      Rollbar.error(ex,
                    supplier_name: supplier.name,
                    supplier_id: supplier.id)
    end

    job.complete_job! if job.may_complete_job?
  end
end
