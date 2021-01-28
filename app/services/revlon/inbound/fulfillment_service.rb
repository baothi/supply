module Revlon::Inbound
  class FulfillmentService
    attr_accessor :csv_content

    def initialize(opts = {})
      validate(opts)
      @csv_content = opts[:csv_content]
    end

    def validate(opts)
      raise 'Content Required' unless opts.has_key?(:csv_content) && opts[:csv_content].present?

      true
    end

    def perform
      ro = ResponseObject.success_response_object(nil, {})
      begin
        order_line_items = parse_csv_into_hash(csv_content)

        order_line_items.each do |order_number, line_items|
          order = Spree::Order.find_by(number: order_number)
          raise "Order ##{order_number} not found.".red  unless order.present?

          fulfill_line_items(order.line_items, line_items)

          order.updater.update_shipment_state
          order.save!
        end
      rescue => ex
        ro.message = "#{ex}"
        ro.success = false
        puts "Issue: #{ex}".red
        # puts "Issue: #{ex.backtrace}".red
      end
      ro
    end

    private

    def fulfill_line_items(local_line_items, line_items_from_csv)
      line_items_from_csv.each do |line_item|
        local_line_item = local_line_items.detect do |li|
          li.original_supplier_sku == line_item[:sku] &&
            li.line_item_number.to_i == line_item[:line_item_number].to_i
        end

        raise "Line item with sku #{line_item[:sku]} not associated with the order.".red unless
            local_line_item.present?

        discrepancy_error = I18n.t('edi.discrepancy_error',
                                   quantity: local_line_item.quantity,
                                   shipped_quantity: line_item[:quantity])
        raise discrepancy_error if local_line_item.quantity != line_item[:quantity].to_i

        local_line_item.fulfill_line_item_shipments!('FESD', line_item[:tracking_number])
      end
    end

    # This generates the optimized hash from csv in the following format
    # {
    #     'order_number_1': [ {line_item_1_details...}, {line_item_2_details...}, ... ],
    #     'order_number_2': [ {line_item_1_details...}, ... ]
    # }
    def parse_csv_into_hash(csv_content)
      order_line_items = {}
      CSV.parse(csv_content, headers: true) do |row|
        order_code, detail, sku, quantity, tracking_numbers = row.fields

        # brand_short_code = order_code[0..2] # 3-digit brand short code
        order_number = order_code[3..-1]

        line_item = {
            line_item_number: detail,
            sku: sku,
            quantity: quantity,
            tracking_number: tracking_numbers.split(';').first
        }
        # csv may contain more than one tracking number.
        # System currently supports only one tracking number to be associated with the shipment.

        order_line_items[order_number] = [] if order_line_items[order_number].blank?
        order_line_items[order_number] << line_item
      end
      order_line_items
    end
  end
end
