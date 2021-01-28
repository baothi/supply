ActiveAdmin.register Spree::SupplierCategoryOption do
  # config.filters = false

  filter :supplier

  actions :index, :show, :edit, :update

  menu label: 'Categories', parent: 'Suppliers'

  controller do
    def update
      resource.update(permitted_params[:supplier_category_option])
      redirect_to resource_path(resource), notice: 'Successfully updated Option!'
    end

    def permitted_params
      params.permit(supplier_category_option: [:platform_category_option_id])
    end
  end

  index download_links: false, pagination_total: false do
    selectable_column

    column :id
    column :supplier
    column :name
    column :updated_at
    column 'Hingeto Supply Corresponding Category', &:platform_category_option
    actions
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :supplier
      f.input :name
      f.input :presentation
      f.input :position
    end
    f.inputs do
      f.input :platform_category_option
    end
    f.actions
  end

  show do
    attributes_table title: 'Category Information' do
      row :supplier
      row :name
      row :presentation
      row 'Hingeto Supply Corresponding Category', &:platform_category_option
    end

    active_admin_comments
  end
end
