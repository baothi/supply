ActiveAdmin.register Spree::Taxon do
  config.filters = false

  menu label: 'Taxons', parent: 'Products'

  actions :all, except: %i(destroy)

  scope :is_license
  scope :is_category
  scope :license_without_outer_banner

  permit_params :inner_banner, :outer_banner

  # action_item :edit_taxon_custom, only: :show do
  #   link_to 'Edit Taxon!', edit_admin_spree_taxon_path(id: resource.slug)
  # end

  controller do
    include CommitWrap

    def find_resource
      scoped_collection.where(slug: params[:id]).first!
    end

    def update
      if resource.update(permitted_params[:taxon])
        redirect_to resource_path(resource), notice: 'Successfully updated!'
      else
        redirect_back(fallback_location: resource_path(resource),
                      alert: resource.errors.full_messages)
      end
    end

    def permitted_params
      params.permit(taxon: %i(name display_name inner_banner outer_banner))
    end
  end

  index download_links: false, pagination_total: false do
    selectable_column

    column :id
    column 'Name' do |taxon|
      link_to taxon.name, admin_spree_taxon_path(id: taxon.slug)
    end
    column :slug
    column 'Outer Banner' do |taxon|
      if taxon.outer_banner.exists?
        image_tag(taxon.outer_banner, width: '250')
      else
        image_tag('noimage/mini-rect.png', width: '250')
      end
    end
    column 'Inner Banner' do |taxon|
      if taxon.inner_banner.exists?
        image_tag(taxon.inner_banner, width: '250')
      else
        image_tag('noimage/mini-rect.png', width: '250')
      end
    end

    actions
  end

  form do |f|
    f.semantic_errors

    inputs do
      input :name
      input :display_name
      input :description
      input :outer_banner
      input :inner_banner
    end

    actions
  end

  show do
    attributes_table title: 'Basic Details' do
      row :id
      row :name
      row :display_name
      row :slug
      # row :permalink
      row :brand
      row :description
      row :created_at
      row :updated_at
    end

    panel 'Product' do
      para 'Here are the first 10 Products from This Taxon.'
      para "There are #{resource.products.count} altogether"
      table_for resource.products.limit(10) do
        column :name do |v|
          link_to v.name,
                  admin_spree_product_path(v)
        end
        column 'Product Status', :submission_state
        column 'Compliant', :submission_compliant
        column 'Availability' do |product|
          product.discontinue_on || 'Active'
        end
        column 'Vendor' do |product|
          product.supplier_brand_name || product.supplier.display_name
        end
        column 'Image' do |product|
          variant_master = product.master
          return if variant_master.nil?

          image = variant_master.active_admin_mini_image
          link_to image_tag(image), admin_spree_product_path(product) unless image.nil?
        end
      end
    end

    attributes_table title: 'Images' do
      row :outer_banner do
        if spree_taxon.outer_banner.exists?
          image_tag(spree_taxon.outer_banner, width: '250')
        else
          image_tag('noimage/mini-rect.png')
        end
      end

      row :inner_banner do
        if spree_taxon.inner_banner.exists?
          image_tag(spree_taxon.inner_banner, width: '250')
        else
          image_tag('noimage/mini-rect.png')
        end
      end
    end
  end
end
