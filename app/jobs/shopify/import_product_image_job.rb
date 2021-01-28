module Shopify
  class ImportProductImageJob < ApplicationJob
    queue_as :images_import
    require 'open-uri'
    require 'digest/md5'

    def perform(job_id)
      puts "About to try to download images..#{job_id}".red

      begin
        @job = Spree::LongRunningJob.find_by(internal_identifier: job_id)
        raise 'Invalid Job' if @job.nil?

        @job.begin_job!
        @job.update_attributes(num_of_records_processed: 0,
                               num_of_records_not_processed: 0,
                               time_started: DateTime.now)
      rescue => ex
        @job.raise_issue!
        @job.log_error("#{ex} \n")
        return
      end

      begin
        product = get_product
        puts "Found product? #{product.present?}"
        return unless product

        set_total_number_of_records(product)

        product.image_urls.each do |url|
          import_image(url, product.master)
          @job.update_log("Image processed for product #{product.name} from #{url} \n")
        end

        # Process Variant Images
        process_variants(product)

        # Update Counter Cache
        product.update_image_counter!
      rescue => ex
        @job.raise_issue!
        @job.log_error("#{ex} \n")
        return
      end
    end

    def process_variants(product)
      variants = product.variants

      variants.each do |variant|
        variant.image_urls.each do |url|
          import_image(url, variant)
          @job.update_log("Image processed for variant of #{product.name} from #{url} \n")
        end
      end
    end

    def get_product
      product_id = @job.option_1
      Spree::Product.find_by(id: product_id)
    end

    def set_total_number_of_records(product)
      variant_images_count = product.variants.reduce(0) { |sum, i| sum + i.image_urls.count }
      product_images_count = product.image_urls.count

      @job.total_num_of_records = variant_images_count + product_images_count
      @job.save
    end

    def import_image(url, obj)
      begin
        @job.update_status(true)

        hash_value = get_hash_value(url)

        if existing_image(hash_value, obj)
          puts "This image has already been imported for #{obj.name}"
          return
        else
          spree_image = Spree::Image.new(viewable: obj, hash_value: hash_value)
          url = URI.parse(url)
          spree_image.attachment = open(url, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)
          spree_image.save!
        end
      rescue => e
        @job.log_error("#{e} \n")
        @job.update_status(false)
      end
    end

    def existing_image(hash_value, obj)
      Spree::Image.find_by(hash_value: hash_value, viewable_id: obj.id)
    end

    def get_hash_value(url)
      tmp_file = Tempfile.new([SecureRandom.hex(10), '.jpg'])
      incoming_file = File.open(tmp_file, 'wb') do |file|
        file << open(url, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE).read
      end
      hash_value = Digest::MD5.file(incoming_file).hexdigest

      hash_value
    end
  end
end
