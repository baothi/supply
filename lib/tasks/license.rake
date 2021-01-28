require 'spree'
namespace :license do
  def create_taxon(taxonomy, root_taxon, license_name)
    return if license_name.blank?

    t = Spree::Taxon.find_or_create_by(name: license_name,
                                       taxonomy: taxonomy)
    t.parent_id = root_taxon.id
    t.save
    t
  end

  desc 'Assign Products To Licenses'
  task assign_products: :environment do
    puts 'Assigning Taxons'.yellow
    taxonomy = Spree::Taxonomy.find_or_create_by(name: 'License')
    root_taxon = Spree::Taxon.find_by(name: 'License')

    licenses = Spree::Product.pluck(:shopify_vendor).uniq
    licenses.each do |license_name|
      taxon = create_taxon(taxonomy, root_taxon, license_name)
      next if taxon.nil?

      Spree::Product.where(shopify_vendor: license_name).find_each do |product|
        taxons = product.taxons
        taxons << taxon unless taxons.include?(taxon)
        product.taxons = taxons

        product.save!
      end
    end
    puts 'Completed Assigning Taxons'.green
  end

  def upload_banners_to_taxons(taxonomy, folder, entries)
    valid_taxons = []
    invalid_taxons = []

    all_license_taxons = Spree::Taxon.where(taxonomy_id: taxonomy.id)
    all_license_taxons.each do |taxon|
      taxon_name = "#{taxon.name}.png"
      next if ['License.png', 'mxed-staging.png'].include?(taxon_name)

      if entries.include?(taxon_name)
        full_path = "#{folder}/#{taxon_name}"
        file = File.open(full_path)
        taxon.outer_banner = file
        taxon.inner_banner = file
        taxon.save!
        valid_taxons << taxon_name  if entries.include?(taxon_name)
      else
        invalid_taxons << taxon_name unless entries.include?(taxon_name)
      end
    end

    puts 'Found Images for:'.green
    valid_taxons.each do |license|
      puts "#{license}".green
    end

    puts 'Unable to find image for:'.red
    invalid_taxons.each do |license|
      puts "#{license}".red
    end
  end

  desc 'Seeds the banner license images'
  task upload_license_banners: :environment do
    # Spree::Taxonomy.destroy_all
    # Spree::Taxon.destroy_all

    # Banners
    folder = "#{Rails.root}/app/assets/images/licenses/banners"
    entries = Dir.entries(folder)

    # entries.map(&:strip)

    taxonomy = Spree::Taxonomy.find_by!(name: 'License')
    # root_taxon = Spree::Taxon.find_by!(name: 'License', parent_id: taxonomy.id)
    upload_banners_to_taxons(taxonomy, folder, entries)
  end

  desc 'Create Taxons based on Shopify'
  task create_taxons_from_shopify_collection: :environment do
    puts 'Initializing taxon creation/update'.green

    taxonomy = Spree::Taxonomy.find_or_create_by(name: 'License')
    root_taxon = Spree::Taxon.find_by(name: 'License')

    Spree::Supplier.find_each do |supplier|
      puts "Working with Supplier: #{supplier.slug}".yellow
      initiate_product_categorization(supplier, taxonomy, root_taxon)
    end

    puts 'Completed Assigning Taxons'.green
  end
end
