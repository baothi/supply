ActiveAdmin.register Spree::OrderIssueReport, as: 'OrderIssueReport' do
  # config.filters = false

  filter :retailer
  filter :resolved?

  actions :all, except: %i(destroy new create edit update)

  menu label: 'Order Issue Reports', parent: 'Orders'

  action_item(:export_as_csv, only: :index) do
    link_to 'Export All As CSV', export_csv_path(klass_name: resource_class.name, columns: %i(
id order_id description resolution decline_reason amount_credited
))
  end

  index download_links: false do
    id_column
    column :order do |issue_report|
      Spree::Order.unscoped do
        link_to issue_report.order.try(:number), admin_spree_order_path(issue_report.order.number)
      end
    end
    column :retailer
    column :retailer_shopify_name do |issue_report|
      link_to issue_report.order.try(:retailer_shopify_name),
              admin_spree_order_path(issue_report.order.number)
    end
    column :resolved?
    column 'State' do |order_issue_report|
      next 'Paid by Supplier' if order_issue_report.resolved_supplier?
      next 'Paid by Hingeto' if order_issue_report.resolved_hingeto?
      next '-- Declined --' if order_issue_report.declined?
    end
    column :description do |order_issue_report|
      order_issue_report.description.try(:truncate, 100)
    end
    actions
  end

  show do |order_issue_report|
    attributes_table do
      row :id
      row 'Shopify Order Name' do
        order_issue_report.order.try(:retailer_shopify_name)
      end
      row :order do
        link_to order_issue_report.order.try(:number),
                admin_spree_order_path(order_issue_report.order.try(:number))
      end
      row :retailer
      row :resolved?
      row 'State' do
        next 'Paid by Supplier' if order_issue_report.resolved_supplier?
        next 'Paid by Hingeto' if order_issue_report.resolved_hingeto?
        next '-- Declined --' if order_issue_report.declined?
      end
      row :description
      row 'Image 1' do
        if  order_issue_report.image1.present?
          image_tag order_issue_report.image1.url, width: '40%'
        else
          'No Image present'
        end
      end
      row 'Image 2' do
        if  order_issue_report.image2.present?
          image_tag order_issue_report.image2.url, width: '40%'
        else
          'No Image present'
        end
      end
      row :created_at
      row :updated_at
    end
  end

  action_item :approve_supplier, only: :show do
    supplier = order_issue_report.order.supplier
    unless order_issue_report.resolved? || !supplier.allow_order_issue_reporting
      submit_tag(
        'Approve – Supplier',
        class: 'approve-issue-report',
        data: {
          'auth-token': form_authenticity_token,
          'order-total': order_issue_report.order.grand_total,
          'submit-url': approve_supplier_admin_order_issue_report_path(order_issue_report.id)
        }
      )
    end
  end

  action_item :approve_hingeto, only: :show do
    unless order_issue_report.resolved?
      submit_tag(
        'Approve – Hingeto',
        class: 'approve-issue-report',
        data: {
          'auth-token': form_authenticity_token,
          'order-total': order_issue_report.order.grand_total,
          'submit-url': approve_hingeto_admin_order_issue_report_path(order_issue_report.id)
        }
      )
    end
  end

  action_item :decline, only: :show do
    unless order_issue_report.resolved?
      link_to(
        'Decline', '#',
        id: 'decline-issue-action-item',
        data: { 'report-id': order_issue_report.id, 'auth-token': form_authenticity_token }
      )
    end
  end

  member_action :approve_supplier, method: :post do
    @report = Spree::OrderIssueReport.find_by(id: params[:id])
    validate_and_set_credit_amount or return
    @report.resolve_as_supplier!
    head :ok
  end

  member_action :approve_hingeto, method: :post do
    @report = Spree::OrderIssueReport.find_by(id: params[:id])
    validate_and_set_credit_amount or return
    @report.resolve_as_hingeto!
    head :ok
  end

  member_action :decline, method: :post do
    report = Spree::OrderIssueReport.find_by(id: params[:id])
    report.decline_reason = params[:reason]
    report.decline!
    head :ok
  end

  controller do
    def validate_and_set_credit_amount
      amount = params[:amount].to_f
      Spree::Order.unscoped do
        if @report.order.grand_total.to_f >= amount
          @report.amount_credited = amount
          flash[:notice] = "Resolved! The retailer has been credited with $#{amount}"
          return true
        end
      end

      flash[:error] = 'You cannot credit amount more than the order total'
      head :not_acceptable
      false
    end
  end
end
