ActiveAdmin.register_page 'Leaderboard' do
  menu priority: 1, label: proc { I18n.t('active_admin.leaderboard') }

  content title: 'Leader board' do
    columns do
      column do
        panel 'Top 5 Retailers with highest referrals' do
          top_retailers = Spree::SupplierReferral.top_retailers_with_highest_referrals
          table_for top_retailers do
            column 'Name' do |entries|
              link_to entries[:retailer].name, admin_spree_retailer_path(entries[:retailer])
            end

            column 'Number of Invites' do |entries|
              entries[:count]
            end
          end
        end
      end

      column do
        panel 'Top 5 Suppliers with highest referrals' do
          top_suppliers = Spree::RetailerReferral.top_suppliers_with_highest_referrals
          table_for top_suppliers do
            column 'Name' do |entries|
              link_to entries[:supplier].name, admin_spree_supplier_path(entries[:supplier])
            end

            column 'Number of Invites' do |entries|
              entries[:count]
            end
          end
        end
      end
    end
  end
end
