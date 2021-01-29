### This seed file is for setting up Platform Categories

taxonomy ||= Spree::Taxonomy.find_or_create_by(name: 'Platform Category')
root_taxon ||= Spree::Taxon.find_or_create_by(name: 'Platform Category')

# Main Tier
categories = 'Accessories,Backpacks,Bed & Bath,Headwear,Jewelry & Watches,Phone Cases,'\
  'Pillows & Throws,Shoes,Slippers,Socks,Sunglasses,Totes & Bags,T Shirts,Underwear,Wallets'

categories = categories.split(',')
categories.each_with_index do |category_name, index|
  # Also create a corresponding Taxon. This may be unnecessary in the future.
  Spree::Taxon.find_or_create_by!(
    name: category_name,
    taxonomy: taxonomy,
    parent: root_taxon
  )

  # Create Platform Category Option
  Spree::PlatformCategoryOption.find_or_create_by!(name: category_name) do |platform_category|
    platform_category.presentation = category_name
    platform_category.position = index * 5
  end
end
