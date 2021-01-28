class Shopify::Variant::PriceUploadWorker
  include Sidekiq::Worker

  include Spree::Calculator::PriceCalculator
  include ImportableJob
  include CancellableJob

  sidekiq_options queue: 'product_import',
                  backtrace: true,
                  retry: 3

  def perform(job_id)
    return if cancelled?
    job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
    job.initialize_and_begin_job! unless job.in_progress?
    @supplier = Spree::Supplier.find_by(id: job.supplier_id)

    begin
      uploaded_variants_hash = extract_data_from_job_file(job)
    rescue => e
      job.log_error(e.to_s)
      JobsMailer.shopify_csv_upload_error(job.id).deliver_now
      return
    end

    job.update(total_num_of_records: uploaded_variants_hash&.length)
    uploaded_variants_hash.each do |hsh|
      break if cancelled?

      begin
        status = upload_variant_cost(hsh)
        job.update_status(status)
      rescue => e
        puts "#{e}".red
        puts "#{e.backtrace}".red
        job.log_error(e.to_s)
        job.update_status(false)
      end
    end

    # Complete Job
    job.complete_job! if job.may_complete_job?
    JobsMailer.shopify_csv_upload_success(job.id).deliver_now
  end

  def upload_variant_cost(hsh)
    variant_cost = Spree::VariantCost.find_by(
      sku: hsh['Variant SKU']&.upcase,
      supplier_id: @supplier.id
    )
    if variant_cost.nil?
      variant_cost = Spree::VariantCost.new
      variant_cost.supplier_id = @supplier.id
      variant_cost.sku = hsh['Variant SKU']&.upcase
    end

    variant_cost_attributes = attributes_from_hash(hsh)
    variant_cost.update_attributes(variant_cost_attributes)
    variant_cost.save!
    puts variant_cost
  end

  def strip_and_convert_hash_values(hsh)
    keys = ['MAP Price',
            'MSRP Price',
            'Variant Price',
            'Variant Compare At Price',
            'Wholesale Cost']
    keys.each do |key|
      hsh[key] = convert_currency_string_to_number(hsh[key])
    end
    hsh
  end

  def attributes_from_hash(hsh)
    result = {}

    # First convert all Price values in the Hash
    # to float using convert_currency_string_to_number
    hsh = strip_and_convert_hash_values(hsh)

    result[:sku] = hsh['Variant SKU']&.strip
    result[:minimum_advertised_price] = hsh['MAP Price']
    result[:msrp] = hsh['MSRP Price']
    result[:cost] =  hsh['Wholesale Cost']
    # result[:price] =  hsh['Wholesale Cost'] # We ignore Price for now

    result.compact
  end

  # def attributes_from_hash(hsh)
  #   result = {}
  #   instance_type = @supplier.instance_type
  #   markup_percentage = @supplier.default_markup_percentage
  #
  #   # First convert all Price values in the Hash
  #   # to float using convert_currency_string_to_number
  #   hsh = strip_and_convert_hash_values(hsh)
  #
  #   result[:map_price] = hsh['MAP Price']
  #   result[:msrp_price] = hsh['MSRP Price']
  #   result[:msrp_price] ||= calc_msrp_price(
  #       hsh['Variant Price'],
  #       hsh['Variant Compare At Price'],
  #       instance_type,
  #       markup_percentage
  #   )
  #   result[:cost_price] =  hsh['Wholesale Cost']
  #   result[:cost_price] ||= calc_cost_price(
  #       hsh['Variant Price'],
  #       instance_type,
  #       markup_percentage
  #   )
  #   result[:price] = calc_price(
  #       hsh['Variant Price'],
  #       instance_type,
  #       markup_percentage,
  #       result[:cost_price]
  #   )
  #   result[:price_management] = 'upload'
  #   result.compact
  # end
end
