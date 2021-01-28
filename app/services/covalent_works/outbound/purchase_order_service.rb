# Generate Invoice for a single order to
# send over to PacSun via CovalentWorks

module CovalentWorks::Outbound
  class PurchaseOrderService
    def initialize(opts = {})
      @required_keys = %i(order)
      @opts = opts
      validate(opts)
      # TODO Remove
      @num_items = @line_items.count
      @final_xml = nil
    end

    def validate(opts)
      @required_keys.each do |key|
        is_present = @opts.has_key?(key) && @opts[key].present?
        raise "#{key.to_s.humanize} is required" unless is_present
      end

      @order = opts[:order]
      @line_items = @order.line_items

      @shipping_address = @order.ship_address
      @billing_address = @order.bill_address

      @retailer = @order.retailer
      @supplier = @order.supplier

      can_send_this_order?
    end

    ###
    # Ensures at least one line_item was shipped
    ###
    def can_send_this_order?
      raise 'This order cannot be invoiced because there arent any line items' if
          @line_items.count.zero?
    end

    # Ensure order is ready to be sent via EDI by ensuring that
    # 1. All Line Items have a number set
    def prep_this_order
      @order.generate_internal_storefront_line_item_identifiers!
    end

    def perform
      ro = ResponseObject.success_response_object(nil, {})
      begin
        prep_this_order
        @final_xml = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
          xml.POs do
            purchase_order_xml(xml)
          end
        end.to_xml
        @final_xml
        upload_to_ftp
        @order.mark_as_sent_via_edi!

        puts "#{@final_xml}".blue
      rescue => ex
        ro.message = "#{ex}"
        ro.success = false
        puts "Issue: #{ex}".red
        # puts "Issue: #{ex.backtrace}".red
      end
      ro
    end

    def upload_to_ftp
      return unless ENV['RAILS_ENV'] == 'production'

      Net::SFTP.start(ENV['CW_FTP_SERVER'],
                      ENV['CW_FTP_USER_NAME'],
                      password: ENV['CW_FTP_PASSWORD']) do |sftp|

        file =
          'Outbox/850/PurchaseOrder' \
          "-#{@order.purchase_order_number.downcase}-#{Time.now.to_i}.xml"

        sftp.file.open(file, 'w') do |f|
          f.puts "#{@final_xml}\n"
        end
      end
    end

    def purchase_order_xml(xml)
      xml.PO do
        xml.Header do
          receiver_id(xml)
          shipping_method_info(xml)
          transaction_info(xml)
          compliance_info(xml)
          po_info(xml)
          customer_order_info(xml)
          contact_info(xml)
          bill_to(xml)
          ship_to(xml)
          ship_from(xml)
          # ac_info(xml)
        end
        summary(xml)
        @line_items.each do |line_item|
          detail(xml, line_item)
        end
      end
    end

    def transaction_info(xml)
      # 00 for original,
      # 01 for cancellation, 04 for change, 05 for replace
      # 06 for confirmation
      xml.TransactionSetPurposeCode '00'
      xml.TransactionID 850
      xml.POTypeCode 'DS'
    end

    def ac_info(xml)
      # A=Allowance
      # C=Charge
      # N=No Allowance or Charge
      # P=Promotion
      xml.ACIndicator 'N'
      # A260=Advertising Allowance
      # D240=Freight
      # D260=Fuel Charge
      # E750=New Store Discount
      # H770=Tax - State Tax
      # ZZZZ=Mutually Defined
      xml.ACCode 'ZZZZ'
      xml.ACAmount 28.3
      # 1=Item List Cost
      # 2=Item Net Cost
      # 3=Discount/Gross
      # 4=Discount/Net
      # 5=Base Price per Unit
      xml.ACPercentQualifier 28.3
      xml.ACPercent 28.3
      # 01=Bill Back
      # 02=Off Invoice
      # 04=Credit Customer Account
      # 05=Charge to be Paid by Vendor
      # 06=Charge to be Paid by Customer"
      xml.ACMethodofHandlingCode 0o2
      xml.ACDescription Faker::Job.field
      # Second Set of allowances
      xml.ACIndicator2 'N'
      xml.ACCode2 'ZZZZ'
      xml.ACAmount2 23
      xml.ACPercentQualifier2 1
      xml.ACPercent2 3
      xml.ACMethodofHandlingCode2 0o2
      xml.ACDescription2 Faker::Job.field
    end

    def shipping_method_info(xml)
      xml.CarrierName @order.requested_shipping_service_code_mapped_to_supplier
    end

    def receiver_id(xml)
      xml.ReceiverID @supplier.edi_identifier
      xml.ReceiverName @supplier.name
    end

    def customer_order_info(xml)
      xml.CustomerOrderNumber @order.retailer_shopify_name
    end

    def po_info(xml)
      xml.PONumber @order.purchase_order_number
      xml.PODate @order.date_order_originally_placed.strftime('%m/%d/%Y')
    end

    def contact_info(xml)
      xml.InternalVendorNumber @supplier.internal_vendor_number
      xml.ContactName "#{@shipping_address.firstname} #{@shipping_address.lastname}"
      xml.ContactPhone @shipping_address.phone
    end

    def ship_to(xml)
      xml.ShipToName "#{@shipping_address.firstname} #{@shipping_address.lastname}"
      # 1=D-U-N-S Number
      # 9=D-U-N-S+4
      # 12=Telephone Number
      # 91=Assigned by Seller
      # 92=Assigned by Buyer
      # UL=UCC/EAN Location Code
      xml.ShipToCodeType 91
      # xml.ShipToCode ''
      xml.ShipToAddress1 @shipping_address.address1
      xml.ShipToAddress2 @shipping_address.address2
      xml.ShipToCity @shipping_address.city
      xml.ShipToState @shipping_address.name_of_state
      xml.ShipToZipCode @shipping_address.zipcode
      xml.ShipToCountry 'US'
    end

    def bill_to(xml)
      # xml.BillToName @retailer.name
      # xml.BillToAddress1 '3450 Miraloma Avenue'
      # xml.BillToAddress2 ''
      # xml.BillToCity 'Placentia'
      # xml.BillToState 'CA'
      # xml.BillToZipCode '92870'
      # xml.BillToCountry 'US'
      xml.BillToName "#{@shipping_address.firstname} #{@shipping_address.lastname}"
      xml.BillToAddress1 @shipping_address.address1
      xml.BillToAddress2 @shipping_address.address2
      xml.BillToCity @shipping_address.city
      xml.BillToState @shipping_address.name_of_state
      xml.BillToZipCode @shipping_address.zipcode
      xml.BillToCountry 'US'
    end

    def compliance_info(xml)
      xml.ShipNoLater (@order.date_order_originally_placed + 3.days).strftime('%m/%d/%Y')
      xml.RequestedShip (@order.date_order_originally_placed + 2.days).strftime('%m/%d/%Y')
    end

    def ship_from(xml)
      xml.ShipFromName @supplier.name
      xml.ShipFromAddress1 @supplier.address1
      xml.ShipFromAddress2 @supplier.address2
      xml.ShipFromCity @supplier.city
      xml.ShipFromState @supplier.state
      xml.ShipFromZipCode @supplier.zipcode
      xml.ShipFromCountry @supplier.country
    end

    def summary(xml)
      total = @order.line_item_total
      quantity_total = @order.quantity_total
      xml.Summary do
        xml.TotalPOAmount total
        xml.TotalQuantityOrdered quantity_total
        xml.NumberofLineItems @num_items
      end
    end

    def detail(xml, line_item)
      variant = line_item.variant
      raise 'Variant cannot be null' if variant.nil?

      opts = {
          line_item: line_item,
          variant: variant
      }

      xml.Detail do
        xml.QuantityInvoiced line_item.quantity
        # CA=Case
        # EA=Each
        # DZ=Dozen
        # LB=Pound
        xml.UnitofMeasurement 'EA'
        # unit_price = line_item.price / line_item.quantity

        # Unit Price
        unit_price = line_item.cost_price
        xml.UnitPrice '%.2f' % unit_price

        # Retail Price
        retail_price = line_item.price
        xml.RetailPrice '%.2f' % retail_price

        # Short Description
        short_desc = variant.product.description.to_s[0..15].upcase
        short_desc =
          Dropshipper::Validator.strip_special_characters(
            short_desc,
            ['<UL>', '</UL>', '<LI>', '</LI>', '<OL>', '</OL>', '<P>', '</P>', '*', '<', '>', '~']
          )
        xml.ItemDescription short_desc
        ids(xml, opts)
      end
    end

    def ids(xml, opts)
      # IN=Buyer's Item Number
      # IT=Buyer's Style Number
      # PI=Purchaser's Item Code
      line_item = opts[:line_item]
      variant = opts[:variant]

      raise "Invalid UPC found for variant: #{variant.original_supplier_sku}" unless
          variant.upc_from_sku_or_direct_upc.to_s.ean?

      xml.BuyerItemQualifier 'PI'
      xml.BuyerItemCode variant.original_supplier_sku
      xml.BuyerItemNumber variant.original_supplier_sku

      # xml.SKUNumber variant_listing.reference_sku
      # xml.SKUNumber variant.reference_sku.rjust(20, '0')
      xml.SKUNumber variant.original_supplier_sku.to_s.rjust(20, '0')
      xml.UPCCode variant.upc_from_sku_or_direct_upc
      xml.VendorItemCode variant.original_supplier_sku
      xml.LineNumber line_item.line_item_number # Optional
    end
  end
end
