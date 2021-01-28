ActiveAdmin.register Spree::TaxonGrouping do
  menu false

  controller do
    def create
      t_grouping = Spree::TaxonGrouping.new(taxon_grouping_params)
      if t_grouping.save
        redirect_to admin_grouping_path(t_grouping.grouping_id),
                    notice: "#{t_grouping.taxon.name} added to #{t_grouping.grouping.name}"
        return
      end

      redirect_to admin_grouping_path(t_grouping.grouping_id),
                  alert: "Error(s) :: #{t_grouping.errors.full_messages.join('. ')}"
    end

    def destroy
      if t_grouping = Spree::TaxonGrouping.destroy(params[:id])
        redirect_to admin_grouping_path(t_grouping.grouping_id),
                    notice: "#{t_grouping.taxon.name} removed successfully"
        return
      end

      redirect_to admin_grouping_path(t_grouping.grouping_id),
                  alert: "Error removing #{t_grouping.taxon.name} from #{t_grouping.grouping.name}"
    end

    def taxon_grouping_params
      params.require(:taxon_grouping).permit(:grouping_id, :taxon_id)
    end
  end
end
