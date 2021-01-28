module Shopify::Licenses
  class BuildFromSmartCollectionService
    attr_accessor :supplier, :root_taxon, :taxonomy

    def initialize(supplier:)
      @supplier = supplier
      @taxonomy = Spree::Taxonomy.find_or_create_by(name: 'License')
      @root_taxon = Spree::Taxon.find_by(name: 'License')
    end

    def perform
      puts 'Initializing taxon creation/update for licenses'.green
      initiate_product_categorization
      puts 'Completed Assigning Taxons'.green
    end

    def initiate_product_categorization
      return if supplier.shopify_credential.nil?

      supplier.initialize_shopify_session!

      # TODO: Refactor this once we have more than 250
      smart_collections = ShopifyAPI::SmartCollection.find(:all, params: { limit: 250 })
      smart_collections.each do |collection|
        puts "Looking at: #{collection.title}"
        taxon = create_taxon_for_smart_collection(taxonomy, root_taxon, collection)
        next if taxon.nil?

        products = ShopifyAPIRetry.retry do
          ShopifyAPI::Product.find(
            :all,
            params: {
                collection_id: collection.id,
                limit: 250
            }
          )
        end

        process_products(products, taxon)

        while products.next_page?
          products = products.fetch_next_page
          process_products(products, taxon)
        end
      end

      supplier.destroy_shopify_session!
    end

    def process_products(products, taxon)
      products.each do |shopify_product|
        assign_taxon_to_local_product(shopify_product, taxon)
      end
    end

    def assign_taxon_to_local_product(shopify_product, taxon)
      local_product = Spree::Product.find_by(shopify_identifier: shopify_product.id)
      return if local_product.nil?

      taxons = local_product.taxons
      taxons << taxon unless taxons.include?(taxon)
      local_product.taxons = taxons

      local_product.save!
    end

    def log_current_collection(collection)
      puts "Attempting to bring in image for: #{collection.title}".yellow
      puts '----'.yellow
      puts "Image URL: #{collection.image.src}".yellow if collection.respond_to?(:image)
      puts '----'.yellow
    end

    def create_taxon_for_smart_collection(taxonomy, root_taxon, collection)
      return if collection.blank? || collection.title.blank?

      begin
        log_current_collection(collection)

        t = Spree::Taxon.find_or_create_by(name: collection.title,
                                           taxonomy: taxonomy)
        t.parent_id = root_taxon.id
        t.banner_from_url(collection.image.src) if collection.respond_to?(:image)
        t.description = ActionView::Base.full_sanitizer.sanitize(collection.body_html)
        t.save!
        t
      rescue => ex
        puts "#{collection.title}".red unless collection.nil?
        puts "#{ex}".red
        nil
      end
    end
  end
end
