ActiveAdmin.register Spree::VariantCost do
  config.filters = true

  menu label: 'Variant Costs', parent: 'Products'

  actions :all, except: %i(new destroy)

  #   action_item :index, only: :index do
  #     link_to 'Export All As CSV', export_csv_path(klass_name: resource_class.name, columns: %i(
  # sku msrp cost minimum_advertised_price supplier_name
  # ))
  #   end

  controller do
    def create
      @variant_cost = Spree::VariantCost.new(permitted_params[:variant_cost])
      if @variant_cost.save
        redirect_to resource_path(@variant_cost), notice: 'Successfully updated!'
      else
        redirect_back(fallback_location: admin_spree_variant_costs_url,
                      alert: @variant_cost.errors.full_messages)
      end
    end

    def update
      if resource.update(permitted_params[:variant_cost])
        redirect_to resource_path(resource), notice: 'Successfully updated!'
      else
        redirect_back(fallback_location: resource_path(resource),
                      alert: resource.errors.full_messages)
      end
    end

    def permitted_params
      params.permit(variant_cost:
                        %i(sku
                           supplier_id
                           msrp
                           cost
                           minimum_advertised_price))
    end
  end

  show do
    @variant_cost = Spree::VariantCost.find(params[:id])
    @versions = @variant_cost.versions.reverse

    attributes_table title: 'Basic Details' do
      row :supplier
      row :sku
      row :msrp_currency
      row :msrp
      row :cost_currency
      row :cost
      row :minimum_advertised_price_currency
      row :minimum_advertised_price
      row :created_at
      row :updated_at
    end

    panel 'Previous Versions' do
      table_for @versions do
        column 'ID', &:id
        column ('Changes') do |v|
          returned_text = ''
          v.changeset.each do |field, value|
            if field != 'updated_at'
              returned_text += "Old #{field}: #{value[0]} | New #{field}: #{value[1]} \n"
            end
          end

          returned_text
        end
        column ('Created at') { |v| v.created_at.strftime('%m/%d/%Y %H:%M') }
      end
    end

    active_admin_comments
  end

  index download_links: [:csv_email], pagination_total: false do
    selectable_column
    column :supplier
    column :sku
    column :msrp
    column :cost
    column :minimum_advertised_price
    column :created_at
    column :updated_at
    actions
  end
end
