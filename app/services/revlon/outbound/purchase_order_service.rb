module Revlon::Outbound
  class PurchaseOrderService
    attr_accessor :csv_content

    def initialize(opts = {})
      @required_keys = %i(orders)
      validate(opts)
      @csv_content = nil
    end

    def validate(opts)
      @required_keys.each do |key|
        is_present = opts.has_key?(key) && opts[key].present?
        raise "#{key.to_s.humanize} is required" unless is_present
      end

      @orders = opts[:orders]

      # Ensure that we are dealing with a collection
      raise 'Collection of orders required' unless
          @orders.respond_to?('each')

      all_orders_belong_to_same_supplier?
    end

    ###
    # Ensures at least one line_item was shipped
    ###
    def can_send_this_order?(order)
      return false if order.line_items.count.zero?

      true
    end

    def all_orders_belong_to_same_supplier?
      supplier_ids = @orders.map(&:supplier_id).uniq
      raise 'All orders must belong to the same supplier (Revlon)' unless
          supplier_ids.count == 1
    end

    def perform
      ro = ResponseObject.success_response_object(nil, {})
      begin
        CSV.generate do |csv|
          @orders.each do |order|
            order.generate_internal_storefront_line_item_identifiers!
            next unless can_send_this_order?(order)

            csv << get_header(number: order.number,
                              completed_at: order.completed_at)

            order.line_items.each do |line_item|
              csv << get_line_item_details(line_item)
            end
            csv << get_shipment_details(order.ship_address)
            csv << get_billing_details(order.bill_address)
          end
          @csv_content = csv.string
          # File.open("#{Rails.root}/tmp/temp_csv_test_#{SecureRandom.hex}.csv", 'w') do |content|
          #   content << csv.string
          # end
        end

        upload_to_ftp
        puts csv_content.green
        # mark_as_sent!
        # @order.mark_as_sent_via_sftp!
      rescue => ex
        ro.message = "#{ex}"
        ro.success = false
        puts "Issue: #{ex}".red
        # puts "Issue: #{ex.backtrace}".red
      end
      ro
    end

    private

    def get_billing_details(address)
      [
          'BILLING',
          address.lastname,
          address.firstname,
          address.address1,
          address.address2,
          address.zipcode,
          address.city,
          address.name_of_state,
          'US'
      ]
    end

    def get_shipment_details(address)
      [
          'SHIPMENT',
          address.lastname,
          address.firstname,
          address.address1,
          address.address2,
          address.zipcode,
          address.city,
          address.name_of_state,
          'US',
          '90000006' # carrier number todo: remove hardcoded. Should be incorporated with the system
      ]
    end

    def get_line_item_details(line_item)
      [
          'DETAIL',
          line_item.line_item_number&.to_i,
          line_item.original_supplier_sku,
          line_item.name,
          line_item.quantity.to_s,
          line_item.price.to_s
      ]
    end

    def get_header(number:, completed_at:)
      date = completed_at.strftime('%Y-%m-%d')
      code = brand_3_digit_code
      ['HEADER', code + number, code, date]
    end

    def brand_3_digit_code
      # Hardcoded for now because this service is utilized by Revlon only.
      # May change in future for other brands as well.
      'BCJ'
    end

    def upload_to_ftp
      return unless ENV['RAILS_ENV'] == 'production'

      SftpService.within_revlon_sftp do |sftp|
        # Todo: change directory according to Revlon requirements
        file = 'In/' \
          "Orders-#{Time.now.to_i}.csv"

        sftp.file.open(file, 'w') do |f|
          f.puts "#{@csv_content}\n"
        end
      end
      puts 'Successfully uploaded'.green
    end
  end
end
