ActiveAdmin.register Spree::Grouping, as: 'Grouping' do
  config.filters = false
  permit_params :name, :description, :group_type

  # actions :all, except: [:destroy]

  # menu parent: 'Licenses'

  index download_links: false, pagination_total: false do
    selectable_column
    column :name do |grouping|
      link_to grouping.name, admin_grouping_path(grouping)
    end
    column :description do |grouping|
      grouping.description.truncate(60)
    end
    column :group_type

    actions
  end

  form do |f|
    f.inputs do
      f.input :name
      f.input :description
      f.input :group_type,
              label: 'Type',
              as: :select,
              collection: Spree::Grouping.group_types.map { |key, value| [key.titleize, value] },
              include_blank: false
    end
    f.para 'Press cancel to return to the list without saving.'
    f.actions
  end

  show do
    attributes_table do
      row :name
      row :group_type
      row :description
    end

    panel 'Member Licenses' do
      table_for grouping.taxon_groupings do
        column :image do |taxon_grouping|
          image_tag(
            outer_banner_or_image_placeholder(taxon_grouping.taxon),
            class: 'standard-width ', height: 40, alt: "#{taxon_grouping.taxon.name}"
          )
        end
        column :name do |taxon_grouping|
          taxon_grouping.taxon.name
        end
        column :taxonomy do |taxon_grouping|
          taxon_grouping.taxon.taxonomy.name
        end
        column :description do |taxon_grouping|
          taxon_grouping.taxon.description
        end
        column 'Action' do |taxon_grouping|
          link_to 'Remove', admin_spree_taxon_grouping_path(taxon_grouping.id), method: :delete
        end
      end
    end

    panel 'Add License' do
      active_admin_form_for Spree::TaxonGrouping.new, url: admin_spree_taxon_groupings_path do |f|
        f.input :grouping_id, as: :hidden, input_html: { value: grouping.id }
        f.input :taxon,
                label: 'License',
                collection: Spree::Taxon.is_license.where.not(id: grouping.taxons.map(&:id))

        f.actions
      end
    end
  end
end
