ActiveAdmin.register Spree::PlatformCategoryOption do
  config.filters = false

  actions :all, except: [:destroy]

  permit_params :name, :presentation, :position

  menu label: 'Categories', parent: 'Platform Options'

  controller do
    def find_resource
      puts 'hello'.red
      scoped_collection.where(id: params[:id]).first!
    end

    def update
      resource.update(permitted_params[:platform_category_option])
      redirect_to resource_path(resource), notice: 'Successfully updated!'
    end

    def create
      resource = Spree::PlatformCategoryOption.new(permitted_params[:platform_category_option])
      if resource.save
        redirect_to resource_path(resource), notice: 'Successfully created!'
      else
        redirect_to :back, alert: "Issues: #{resource.errors.full_messages}"
      end
    end

    def permitted_params
      params.permit(platform_category_option:
                        %i(name presentation position))
    end
  end

  form do |f|
    f.semantic_errors
    inputs do
      input :name
      input :presentation
      input :position
    end

    actions
  end
end
