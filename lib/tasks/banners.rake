require 'spree'

namespace :banner do
  desc 'Create CustomCollection taxonomy'
  task create_custom_collection_taxonomy: :environment do
    Spree::Taxonomy.find_or_create_by(name: 'CustomCollection')
    puts 'CustomCollection taxonomy created.'.green
  end

  desc 'Create Foundmi and Top-Sellers taxons with banner'
  task create_foundmi_and_top_sellers: :environment do
    custom_collection = Spree::Taxonomy.find_or_create_by(name: 'CustomCollection')
    puts 'Found or created "CustomCollection" taxonomy'.green

    Spree::Taxon.find_or_initialize_by(name: 'foundmi').tap do |taxon|
      taxon.update(
        taxonomy: custom_collection,
        outer_banner: File.open(Rails.root.join('app', 'assets', 'images', 'foundmi.jpg')),
        inner_banner: File.open(Rails.root.join('app', 'assets', 'images', 'foundmi.jpg'))
      )
    end
    puts 'Found or created "foundmi" taxon'.green

    Spree::Taxon.find_or_initialize_by(name: 'top-sellers').tap do |taxon|
      taxon.update(
        taxonomy: custom_collection,
        outer_banner: File.open(Rails.root.join('app', 'assets', 'images', 'top-sellers.jpg')),
        inner_banner: File.open(Rails.root.join('app', 'assets', 'images', 'top-sellers.jpg'))
      )
    end
    puts 'Found or created "top-sellers" taxon'.green
  end
end
