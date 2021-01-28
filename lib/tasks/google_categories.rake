namespace :google_categories do
  desc 'Generate google product groupings'
  task generate: :environment do
    google_taxonomy = Spree::Taxonomy.find_or_create_by(name: 'Google Categories')
    root = Spree::Taxon.find_by(name: google_taxonomy.name)

    file = File.read(Rails.root.join('Google_Product_Taxonomy_Version_2015_02_19.txt'))
    file.lines.each do |line|
      next if line.strip.first == '#'

      parent = root
      google_id, category_nesting = line.split(' - ')
      category_nesting.strip.split(' > ').each do |category|
        parent = create_descendant_taxon_for(parent, category, google_id)
      end
    end
    puts 'Done!'
  end

  def create_descendant_taxon_for(parent, category, google_id)
    child = Spree::Taxon.
            find_or_initialize_by(name: category.strip, parent: parent, taxonomy: parent.taxonomy)

    child.update(
      google_category_id: google_id.to_i,
      google_category_nested_string: calculate_category_nesting(child)
    )

    child
  end

  def calculate_category_nesting(child)
    return child.name if child.parent.nil? || child.parent.parent.nil?

    calculate_category_nesting(child.parent) + ' > ' + child.name
  end
end
