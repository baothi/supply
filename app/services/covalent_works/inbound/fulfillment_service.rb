# Generate Invoice to send over to PacSun via CW
module CovalentWorks::Inbound
  class FulfillmentService
    include Xml::XmlHelper

    def initialize(opts = {})
      validate(opts)
      @content = opts[:content]
    end

    def validate(opts)
      raise 'Content Required' unless opts.has_key?(:content) && opts[:content].present?

      true
    end

    def perform
      # For Testing, uncomment this line
      # @content =
      # File.read("#{Rails.root}/spec/fixtures/edi/fulfillment/sample_1.xml")
      # @content = File.read("#{Rails.root}/spec/fixtures/edi/fulfillment/test.xml")
      process_asns
    end

    def extract_line_item_fulfillments(asn_node)
      # First unpack all items
      po_number = parse_text_for_element(asn_node, 'PONumber')
      shipment_node = asn_node.at_css('Shipment')
      packages = shipment_node.search('Package')

      line_items = []
      packages.each do |package_node|
        tracking = parse_text_for_element(package_node, 'CartonID')

        items = package_node.search('Item')
        # puts "Items: #{items}".blue

        items.each do |item_node|
          item = OpenStruct.new
          item.po_number = po_number
          item.tracking_number = tracking
          shipped_quantity = parse_text_for_element(item_node, 'ShippedQuantity')
          item.shipped_quantity = shipped_quantity.to_i unless shipped_quantity.nil?
          ordered_quantity = parse_text_for_element(item_node, 'OrderedQuantity')
          item.ordered_quantity = ordered_quantity.to_i unless ordered_quantity.nil?
          item.upc = parse_text_for_element(item_node, 'UPCCode')
          item.line_number = parse_text_for_element(item_node, 'POLineNumber')
          line_items << item
        end
      end

      # We want to group the line items
      grouped_line_items = group_line_items(line_items)
      grouped_line_items
    end

    def group_line_items(line_items)
      # Now go through each item and group together
      # We assume that each ASN can only related to one PO number.
      # TODO: Verify that the above is the case.
      unique_items = {}
      line_items.each do |line_item|
        line_number = line_item.line_number
        po_number = line_item.po_number
        raise 'Issue: Line Number cannot be nil for this ASN' if line_number.nil?
        raise 'Issue: PO Number cannot be nil for this ASN' if po_number.nil?

        key = line_number.to_sym

        unique_items[key] = [] unless
            unique_items.key?(key)

        unique_items[key] << line_item
      end
      # puts "#{unique_items.inspect}".yellow
      unique_items
    end

    def validate_line_items(line_items)
      # We are mostly checking that the line item contains what it says it does.
      master_items = []
      line_items.each_key do |key|
        items = line_items[key]
        first_item = items[0]
        master_item = OpenStruct.new
        master_item.tracking_number = first_item.tracking_number
        master_item.upc = first_item.upc
        master_item.po_number = first_item.po_number
        master_item.line_number = first_item.line_number

        master_item.shipped_quantity = items.sum(&:shipped_quantity)
        # We use the first_item because we expect that line_item ordered quantity
        # should be the same across all these line_items
        # (and all these items are grouped by line item)
        master_item.ordered_quantity = first_item.ordered_quantity
        # puts "Comparising: #{master_item.shipped_quantity}
        # with #{master_item.ordered_quantity}".blue

        # This is just a preliminary check. We will still check against
        # the original line item in another method.
        if master_item.shipped_quantity != master_item.ordered_quantity
          raise 'We require both the shipped_quantity & ordered_quantity to '\
            "be fulfilled at the same time for line # #{master_item.line_number}"
        end

        master_items << master_item
      end

      master_items
    end

    def fulfill_line_items(master_items)
      master_items.each do |master_item|
        line_item = Spree::LineItem.find_by(
          line_item_number: master_item.line_number,
          purchase_order_number: master_item.po_number
        )

        error = I18n.t('edi.invalid_asn_reference',
                       line_number: master_item.line_number,
                       po_number: master_item.po_number)
        raise error if line_item.nil?

        discrepancy_error = I18n.t('edi.discrepancy_error',
                                   quantity: line_item.quantity,
                                   shipped_quantity: master_item.shipped_quantity)
        raise discrepancy_error if
            line_item.quantity != master_item.shipped_quantity

        fulfill_line_item!(line_item, 'FESD', master_item.tracking_number)
        line_item
      end
    end

    def fulfill_line_item!(line_item, courier_service, tracking_number)
      order = line_item.order
      line_item.fulfill_line_item_shipments!(courier_service, tracking_number)
      order.updater.update_shipment_state
      order.save!
      begin
        # TODO: Add method & update
        # order.generate_document!
      rescue => ex
        puts "Unable to generate packing slip due to: #{ex}".red
      end
    end

    def email_error
      # TODO
    end

    def validate_supplier
      edi_identifier = parse_text_for_element(@doc, 'SenderID')
      internal_vendor_number = parse_text_for_element(@doc, 'InternalVendorNumber')
      @supplier = Spree::Supplier.find_by(
        internal_vendor_number: internal_vendor_number,
        edi_identifier: edi_identifier
      )

      error = I18n.t(
        'edi.invalid_supplier',
        internal_vendor_number: internal_vendor_number,
        edi_identifier: edi_identifier
      )
      raise error if @supplier.nil?
    end

    def process_asns
      ro = ResponseObject.success_response_object(nil, {})
      successful = []
      failed = []

      begin
        @doc = Nokogiri::XML(@content)

        # Ensure we have a valid supplier
        validate_supplier

        # TODO: First check to ensure we haven't yet processed this document.
        generated_asns = []
        asns = @doc.at_css('ASNs').elements
        # puts "#{asns}".yellow
        asns.each do |asn_node|
          # We first store the reference ASN document.
          asn = parse_asn_node(asn_node)

          if asn.save
            line_items = extract_line_item_fulfillments(asn_node)
            master_items = validate_line_items(line_items)
            fulfill_line_items(master_items)
            generated_asns << asn
          end
        end
        ro.message = 'Successfully processed!'
        ro.success = true
        ro.success_objects = successful
        ro.error_objects = failed
      rescue => ex
        ro.message = "#{ex}"
        ro.success = false
        # puts "Issue: #{ex}".red
        # puts "Issue: #{ex.backtrace}".red
        email_error
      end
      ro
    end

    def parse_order_node(node, asn)
      asn.purchase_order_number = parse_text_for_element(node, 'PONumber')
      po_created_at = parse_text_for_element(node, 'PODate')
      asn.po_created_at = Date.strptime(po_created_at, '%m/%d/%Y') unless
          po_created_at.nil?
      asn
    end

    def parse_base_info(node, asn)
      asn.customer_order_number = parse_text_for_element(node, 'CustomerOrderNumber')
      asn.internal_vendor_number = parse_text_for_element(node, 'InternalVendorNumber')
      asn.asn_number = parse_text_for_element(node, 'ASNNumber')
      date = parse_text_for_element(node, 'ASNDate')
      time = parse_text_for_element(node, 'ASNTime')

      asn.asn_generated_at = DateTime.strptime("#{date}T#{time}", '%m/%d/%YT%H:%M')
      asn
    end

    def parse_shipping_method_info(node, asn)
      asn.scac_code = parse_text_for_element(node, 'SCACCode')
      asn.carrier_name = parse_text_for_element(node, 'CarrierName')
      asn
    end

    def parse_sender_info(node, asn)
      asn.sender_name = parse_text_for_element(node, 'SenderName')
      asn.sender_identifier = parse_text_for_element(node, 'SenderID')
      asn
    end

    def parse_shipping_info(node, asn)
      shipped_date = parse_text_for_element(node, 'ShippedDate')

      asn.shipped_date = Date.strptime(shipped_date, '%m/%d/%Y') unless
          shipped_date.nil?

      estimated_delivery_date = parse_text_for_element(node, 'EstimatedDeliveryDate')
      asn.estimated_delivery_date = Date.strptime(estimated_delivery_date, '%m/%d/%Y') unless
          estimated_delivery_date.nil?
      asn
    end

    def parse_asn_node(asn_node)
      asn = Spree::Edi::FulfillmentNotice.new
      asn = parse_sender_info(asn_node, asn)
      asn = parse_base_info(asn_node, asn)
      # TODO: Raise ERROR for SCSC code or
      asn = parse_shipping_method_info(asn_node, asn)
      asn = parse_shipping_info(asn_node, asn)

      order_node = asn_node.at_css('Order')
      asn = parse_order_node(order_node, asn)

      # puts "ASN #{asn.inspect}".green

      asn
    end
  end
end
