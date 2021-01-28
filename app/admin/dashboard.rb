ActiveAdmin.register_page 'Dashboard' do
  menu priority: 1, label: proc { I18n.t('active_admin.dashboard') }

  page_action :export_csv_as_email, method: :get do
    case params[:resource_class]
    when 'spree_products'
      params.permit(:q)
      Spree::ProductCsv.start_job(params[:q], current_spree_user.id)
      redirect_to admin_dashboard_path,
                  notice: 'Download started. You will get an emails once it completes.'
    when 'spree_variant_costs'
      params.permit(:q)
      Spree::VariantCostCsv.start_job(params[:q], current_spree_user.id)
      redirect_to admin_dashboard_path,
                  notice: 'Download started. You will get an emails once it completes.'
    else
      redirect_back fallback_location: admin_spree_products_path, alert: 'Invalid Resource'
    end
  end

  content title: 'Dashboard' do
    render partial: 'custom_dashboard_title', locals: { params: params }

    params[:period] ||= 'all-times'
    params[:from] ||= Time.now.to_s
    params[:to] ||= Time.now.to_s

    columns do
      column do
        panel 'Stores with Order(s)' do
          Spree::Order.fulfilled.distinct(:retailer_id).within_interval(params).count
        end
      end
      column do
        panel 'No of Retailers' do
          Spree::Retailer.within_interval(params).count
        end
      end
      column do
        panel 'No of Product Listings' do
          Spree::ProductListing.within_interval(params).count
        end
      end
    end

    columns do
      column do
        panel 'All Orders' do
          Spree::Order.complete.within_interval(params).count
        end
      end
      column do
        panel 'Paid Orders' do
          Spree::Order.paid.within_interval(params).count
        end
      end
      column do
        panel 'Unpaid Orders' do
          Spree::Order.unpaid.within_interval(params).count
        end
      end
      column do
        panel 'Fulfilled Orders' do
          Spree::Order.fulfilled.within_interval(params).count
        end
      end
      column do
        panel 'Unfulfilled Orders' do
          Spree::Order.unfulfilled.within_interval(params).count
        end
      end
      column do
        panel 'Pending Order Issues' do
          Spree::OrderIssueReport.pending.within_interval(params).count
        end
      end
    end

    columns do
      column do
        panel '5 Recent Orders' do
          table_for Spree::Order.complete.within_interval(params).last(5) do
            column 'Order Number' do |order|
              link_to order.number, admin_spree_order_path(order)
            end
            column 'Total (USD)', &:total
            column :payment_state
            column :shipment_state
            column :completed_at
          end
        end
      end

      column do
        panel '5 Recent Retailers' do
          table_for Spree::Retailer.within_interval(params).last(5) do
            column :name do |retailer|
              link_to retailer.name, admin_spree_retailer_path(retailer)
            end
            # column :shop_owner
            # column 'Shopify Link' do |retailer|
            #   next unless retailer.shopify_url.present?
            #   link_to retailer.shopify_slug, "http://#{retailer.shopify_url}", target: '_blank'
            # end
            column 'Installed At', &:created_at
          end
        end
      end

      column do
        panel '5 Recent Pending Order Issues' do
          table_for Spree::OrderIssueReport.pending.within_interval(params).last(5) do
            column 'Order Number' do |issue_report|
              Spree::Order.unscoped do
                unless issue_report.order.nil?
                  link_to issue_report.order.number,
                          admin_spree_order_path(issue_report.order.number)
                  link_to issue_report.order.number,
                          admin_spree_order_path(issue_report.order.number)
                end
              end
            end
            column 'Reported At', &:created_at
            column 'View Issue' do |issue_report|
              link_to 'View', admin_order_issue_report_path(issue_report.id)
            end
          end
        end
      end
    end

    columns do
      column do
        panel 'Retailers Awaiting Access' do
          table_for Spree::Retailer.awaiting_access.within_interval(params) do
            column :name do |retailer|
              link_to retailer.name, admin_spree_retailer_path(retailer)
            end
            column 'Joined At', &:created_at
            column 'Number of invites sent' do |retailer|
              Spree::SupplierReferral.where(spree_retailer_id: retailer.id).count
            end
          end
        end
      end
    end
  end
end
