module Dsco::Licenses
  class BuildFromProductService
    attr_accessor :supplier, :root_taxon, :root_taxonomy

    def initialize(supplier:)
      @supplier = supplier
      @root_taxonomy = Spree::Taxonomy.find_or_create_by(name: 'License')
      @root_taxon = Spree::Taxon.find_by(name: 'License')
      raise 'Licensing Taxonomy not found' if @root_taxonomy.nil? || @root_taxon.nil?
    end

    def perform
      puts 'Initializing taxon creation/update for licenses'.green
      initiate_product_categorization
      puts 'Completed Assigning Taxons'.green
    end

    def initiate_product_categorization
      supplier.products.find_each do |local_product|
        # We store license name on supplier_brand_name
        taxon = create_taxon_for_license(local_product.supplier_brand_name)
        next if taxon.nil?

        assign_taxon_to_local_product(local_product, taxon)
      end
    end

    def create_taxon_for_license(license_name)
      begin
        t = Spree::Taxon.find_or_create_by(
          parent_id: root_taxon.id,
          name: license_name,
          taxonomy_id: @root_taxonomy.id
        )
        # t.parent_id = root_taxon.id
        t.save!
        t
      rescue => ex
        puts "#{license_name}".red unless license_name.blank?
        puts "#{ex}".red
        nil
      end
    end

    def assign_taxon_to_local_product(local_product, taxon)
      return if local_product.nil?

      taxons = local_product.taxons
      taxons << taxon unless taxons.include?(taxon)
      local_product.taxons = taxons

      local_product.save!
    end
  end
end
