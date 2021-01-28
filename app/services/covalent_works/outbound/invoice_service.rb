# Generate Invoice for a single order to
# send over to PacSun via CovalentWorks

module CovalentWorks::Outbound
  class InvoiceService
    def initialize(opts = {})
      @required_keys = %i(order)
      @opts = opts
      validate(opts)
      # TODO Remove
      @num_items = @fulfilled_line_items.count
      @final_xml = nil
    end

    def validate(opts)
      @required_keys.each do |key|
        is_present = @opts.has_key?(key) && @opts[key].present?
        raise "#{key.to_s.humanize} is required" unless is_present
      end

      @order = opts[:order]
      @fulfilled_line_items = @order.fulfilled_line_items

      @shipping_address = @order.ship_address
      @billing_address = @order.bill_address

      @supplier = @order.supplier

      raise 'Supplier must provide EDI ID' if
         @supplier.edi_identifier.blank?

      raise 'Supplier must have Vendor Number' if
          @supplier.internal_vendor_number.blank?

      @retailer = @order.retailer
      @supplier = @order.supplier

      can_invoice_against_this_order?
    end

    ###
    # Ensures at least one line_item was shipped
    ###
    def can_invoice_against_this_order?
      raise 'This order cannot be invoiced because there arent any fulfilled line items' if
          @fulfilled_line_items.count.zero?
    end

    def perform
      @final_xml = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
        xml.Invoices do
          invoice_xml(xml)
        end
      end.to_xml
      @final_xml
      upload_to_ftp
      puts "#{@final_xml}".blue
    end

    def upload_to_ftp
      return unless ENV['RAILS_ENV'] == 'production'

      Net::SFTP.start(ENV['CW_FTP_SERVER'],
                      ENV['CW_FTP_USER_NAME'],
                      password: ENV['CW_FTP_PASSWORD']) do |sftp|

        file = "Outbox/810/Invoice-#{@order.purchase_order_number.downcase}-#{Time.now.to_i}.xml"

        sftp.file.open(file, 'w') do |f|
          f.puts "#{@final_xml}\n"
        end
      end
    end

    def invoice_xml(xml)
      xml.Invoice do
        xml.Header do
          sender_id(xml)
          receiver_id(xml)
          terms_info(xml)
          invoice_info(xml)
          po_info(xml)
          customer_order_info(xml)
          contact_info(xml)
          ship_to(xml)
          fulfillment_info(xml)
        end
        summary(xml)
        @fulfilled_line_items.each do |line_item|
          detail(xml, line_item)
        end
      end
    end

    def terms_info(xml)
      xml.TermsTypeCode '01'
      xml.TermsNetDueDate (DateTime.now + 30.days).strftime('%m/%d/%Y')
      xml.TermsNetDays 30
      xml.TermsDescription 'Net 30'
    end

    def sender_id(xml)
      xml.SenderID @supplier.edi_identifier
      xml.SenderName @supplier.name.upcase
    end

    def receiver_id(xml)
      xml.ReceiverID ENV['PACSUN_EDI_ID']
      xml.ReceiverName 'PacSun'
    end

    def invoice_info(xml)
      xml.InvoiceDate DateTime.now.strftime('%m/%d/%Y')
      xml.InvoiceNumber @order.purchase_order_number
    end

    def customer_order_info(xml)
      xml.CustomerOrderNumber @order.retailer_order_number
    end

    def po_info(xml)
      xml.PONumber @order.purchase_order_number
      xml.PODate @order.created_at.strftime('%m/%d/%Y')
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
      xml.ShipToCode ''
      xml.ShipToAddress1 @shipping_address.address1
      xml.ShipToAddress2 @shipping_address.address2
      xml.ShipToCity @shipping_address.city
      xml.ShipToState @shipping_address.state_text
      xml.ShipToZipCode @shipping_address.zipcode
      xml.ShipToCountry 'US'
    end

    def bill_to(xml)
      xml.BillToName @retailer.name
      xml.BillToAddress1 '3450 Miraloma Avenue'
      xml.BillToAddress2 ''
      xml.BillToCity 'Placentia'
      xml.BillToState 'CA'
      xml.BillToZipCode '92870'
      xml.BillToCountry 'US'
    end

    def fulfillment_info(xml)
      xml.ShippedDate @order.created_at.strftime('%m/%d/%Y')
    end

    def ship_from(xml)
      address = @supplier.shipping_address
      return if address.nil?

      xml.ShipFromName @supplier.name
      xml.ShipFromAddress1 address.address1
      xml.ShipFromAddress2 address.address2
      xml.ShipFromCity address.city
      xml.ShipFromState address.state_text
      xml.ShipFromZipCode address.zipcode
      xml.ShipFromCountry 'US'
    end

    def summary(xml)
      total = @order.fulfilled_line_item_total
      xml.Summary do
        xml.TotalInvoiceAmount total
        xml.TotalExtendedLineAmount total
        xml.TotalInvoiceAmountLessTermsDiscount total
        xml.NumberofLineItems @num_items
      end
    end

    def detail(xml, line_item)
      variant_listing = line_item.variant_listing
      raise 'Variant Listing cannot be null' if variant_listing.nil?

      variant = variant_listing.variant
      raise 'Variant cannot be null' if variant.nil?

      opts = {
          line_item: line_item,
          variant_listing: variant_listing,
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
        # xml.UnitPrice '%.2f' % unit_price

        # Unit Price
        unit_price = line_item.basic_cost
        xml.UnitPrice '%.2f' % unit_price

        # Short Description
        short_desc = variant_listing.description.to_s[0..15].upcase
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
      variant_listing = opts[:variant_listing]
      variant = opts[:variant]

      # xml.SKUNumber variant_listing.reference_sku

      short_sku = if variant_listing.storefront_identifier.present?
                    variant_listing.storefront_identifier.rjust(10, '0')
                  end

      xml.BuyerItemQualifier 'PI'
      xml.BuyerItemNumber short_sku

      # xml.SKUNumber short_sku

      xml.UPCCode variant_listing.upc_or_retailer_assigned_upc
      xml.VendorItemCode variant.vendor_style_identifier
      xml.LineNumber line_item.store_front_line_item_identifier # Optional
    end
  end
end
