ActiveAdmin.register Spree::LongRunningJob, as: 'Data Import/Export Status' do
  # permit_params :name, :slug, :description, :email, :website, :logo

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # permit_params :list, :of, :attributes, :on, :model
  #
  # or
  #
  # permit_params do
  #   permitted = [:permitted, :attributes]
  #   permitted << :other if resource.something?
  #   permitted
  # end

  # actions :all, :only => [:create]    '

  config.per_page = 25

  filter :job_type
  filter :created_at

  actions :all, except: %i(edit destroy new)

  index download_links: false, pagination_total: false do
    selectable_column
    column :id
    column :job_type
    column :status
    column :progress do |job|
      amount = job.progress.to_f / 100
      if job.completed?
        progress_bar amount, label: true, style: 'min-width: 20px', alternative: 'success'
      elsif job.scheduled?
        'N/A'
      else
        progress_bar amount, label: true, style: 'min-width: 20px', alternative: 'warning'
      end
    end
    column :created_at
    # attachment_column :output_csv_file
    actions defaults: true do |job|
      # link_to "Download Results", job.output_csv_file.url if job.is_output_file_available?
    end
  end

  show do |_lrj|
    attributes_table do
      row :retailer
      row :supplier
      row :job_type
      row :status
      row :progress
      row :option_1
      row :option_2
      row :option_3
      row :option_4
      row :option_5
      row :log
      row :error_log
      row :output do |job|
        if job.output_csv_file?
          link_to 'Download Output File', job.output_csv_file.url
        else
          'N/A'
        end
      end
    end
  end

  # show do |product|
  #   attributes_table do
  #     row :brand
  #     row :action_type
  #     row :job_type
  #     row :status
  #     row :progress do |job|
  #       amount = job.progress.to_f/100
  #       if job.status==LongRunningJob::COMPLETED
  #         progress_bar amount, label: true, style: 'min-width: 20px', alternative: 'success'
  #       elsif job.status==LongRunningJob::SCHEDULED
  #         "N/A"
  #       else
  #         progress_bar amount, label: true, style: 'min-width: 20px', alternative: 'warning'
  #       end
  #     end
  #
  #     row :input do |job|
  #       if job.has_input_file? && job.input_csv_file
  #         link_to "Download Input File", job.input_csv_file.url
  #       else
  #         "N/A"
  #       end
  #     end
  #
  #     row :output_file do |job|
  #       if job.has_output_file? && job.output_csv_file?
  #         link_to "Download Output File", job.output_csv_file.url
  #       else
  #          "N/A"
  #       end
  #     end
  #
  #     row :log
  #
  #   end
  #   active_admin_comments
  # end
end
