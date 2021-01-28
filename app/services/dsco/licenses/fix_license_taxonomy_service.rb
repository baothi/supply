# Used for fixing some legacy taxons where we didn't properly assign the taxonomy_id
# Usage - Dsco::Licenses::FixLicenseTaxonomyService.new.perform
module Dsco::Licenses
  class FixLicenseTaxonomyService
    attr_accessor :supplier, :root_taxon, :root_taxonomy

    def initialize
      @root_taxonomy = Spree::Taxonomy.find_or_create_by(name: 'License')
      @root_taxon = Spree::Taxon.find_by(name: 'License')
      raise 'Licensing Taxonomy not found' if @root_taxonomy.nil? || @root_taxon.nil?
    end

    def perform
      Spree::Taxon.where(taxonomy_id: nil).find_each do |taxon|
        begin
          if taxon.parent_id == @root_taxon.id
            taxon.taxonomy_id = @root_taxonomy.id
            taxon.save!
          end
        rescue => ex
          puts "#{ex}".red
        end
      end
    end
  end
end
