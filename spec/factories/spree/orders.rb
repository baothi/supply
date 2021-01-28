FactoryBot.define do
  factory :spree_order, class: Spree::Order do
    user factory: :spree_user
    retailer factory: :spree_retailer
    supplier factory: :spree_supplier
    bill_address
    ship_address
    completed_at { nil }
    source { nil }
    email { user.email }
    store

    transient do
      line_items_price { 10 }
    end

    factory :spree_order_with_line_items do
      bill_address
      ship_address

      transient do
        line_items_count { 1 }
        shipment_cost { 100 }
        shipping_method_filter { Spree::ShippingMethod::DISPLAY_ON_FRONT_END }
      end

      after(:create) do |order, evaluator|
        create_list(
          :spree_line_item,
          evaluator.line_items_count,
          order: order,
          price: evaluator.line_items_price
        )
        order.line_items.reload

        create(:shipment, order: order, cost: evaluator.shipment_cost)
        order.shipments.reload

        order.update_with_updater!

        order.set_searchable_attributes
      end

      factory :spree_completed_order_with_totals do
        state { 'complete' }
        after(:create) do |order, evaluator|
          order.refresh_shipment_rates(evaluator.shipping_method_filter)
          order.update_column(:completed_at, Time.current)
          order.line_items.each do |line_item|
            line_item.variant.stock_items.update_all(count_on_hand: 10)
          end
        end

        factory :spree_order_ready_to_ship do
          state { 'complete' }
          payment_state { 'paid' }
          shipment_state { 'ready' }

          after(:create) do |order|
            create(:payment, amount: order.total, order: order, state: 'completed')
            order.shipments.each do |shipment|
              shipment.inventory_units.update_all state: 'on_hand'
              shipment.update_column('state', 'ready')
            end
            order.update_columns(shopify_sent_at: Time.now)
            create(:spree_shopify_credential, teamable: order.supplier)
            order.reload
          end

          factory :spree_shipped_order do
            after(:create) do |order|
              order.shipments.each do |shipment|
                shipment.inventory_units.update_all state: 'shipped'
                shipment.update_column('state', 'shipped')
              end
              order.update_columns(shipment_state: 'shipped', supplier_shopify_order_name: '#9999')
              order.reload

              order.line_items.each do |line_item|
                line_item.update(retailer_shopify_identifier: rand(1000000000))
              end
            end
          end
        end
      end
    end
  end
end
