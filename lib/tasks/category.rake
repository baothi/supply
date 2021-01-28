require 'spree'
namespace :category do
  def find_or_create_category_taxon(product)
    return if product.shopify_product_type.blank?

    @taxonomy ||= Spree::Taxonomy.find_or_create_by(name: 'Category')
    @root_taxon ||= Spree::Taxon.find_or_create_by(name: 'Category')

    taxon = Spree::Taxon.find_or_initialize_by(
      name: product.shopify_product_type,
      taxonomy: @taxonomy,
      parent: @root_taxon
    )

    puts "Created new category, '#{taxon.name}'" if taxon.new_record?

    taxon = set_default_banner(taxon, product) unless taxon.outer_banner.exists?
    taxon.save
    taxon
  end

  def set_default_banner(taxon, product)
    images = product.images
    return taxon if images.empty?
    return taxon unless images.first.attachment.exists?

    taxon.outer_banner = images.first.attachment
    taxon.inner_banner = images.first.attachment

    puts "Assigned category, #{taxon.name} a default image from the product"
    taxon
  end

  desc 'Assign Products To Category'
  task categorize_products: :environment do
    puts 'Categorizing Products by "shopify_product_type"'.yellow

    Spree::Supplier.find_each do |supplier|
      puts "Categorizing for #{supplier.name}".yellow

      supplier_products =
        Spree::Product.where.not(shopify_product_type: nil).where(supplier_id: supplier.id)

      supplier_products.find_each do |product|
        next unless taxon = find_or_create_category_taxon(product)
        next if product.taxons.include?(taxon)

        product.taxons << taxon
        product.save
      end
    end

    puts 'Completed Assigning Category Taxons'.green
  end
end
