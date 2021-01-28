ActiveAdmin.register Spree::FeaturedBanner, as: 'FeaturedBanner' do
  config.filters = false
  permit_params :title, :description, :taxon_id, :image

  index download_links: false, pagination_total: false do
    column :image do |banner|
      image_tag(banner.image(:small), height: 40, alt: "#{banner.title}")
    end
    column :title do |banner|
      link_to banner.title, admin_featured_banner_path(banner)
    end
    column :description do |banner|
      banner.description.truncate(60)
    end
    column 'Collection', :taxon
  end

  show do
    attributes_table do
      row :title
      row :description
      row 'Collection', &:taxon
      row :image do |banner|
        image_tag(banner.image(:small), alt: "#{banner.title}")
      end
    end
  end

  form do |f|
    f.semantic_errors

    inputs do
      input :title
      input :description
      input :taxon,
            as: :select,
            collection: option_groups_from_collection_for_select(
              Spree::Taxonomy.featureable, :featureable_taxons, :name, :id, :name,
              featured_banner.taxon_id
            )
      input :image
    end

    actions
  end
end
