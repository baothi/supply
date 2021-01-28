# Ingest Invoice from Supplier
module CovalentWorks::Inbound
  class InventoryService
    include Xml::XmlHelper

    attr_accessor :supplier

    def initialize(opts = {})
      validate(opts)
      @content = opts[:content]
      @supplier = nil
    end

    def validate(opts)
      # For Testing, uncomment this line.
      # @content = File.read("#{Rails.root}/spec/fixtures/edi/inventory/sample_1.xml")
      raise 'Content Required' unless opts.has_key?(:content) && opts[:content].present?

      true
    end

    def perform
      process_inventory
    end

    def email_error
      # TODO
    end

    def validate_supplier(inventory_report)
      edi_identifier = parse_text_for_element(inventory_report, 'SenderID')
      internal_vendor_number =
        parse_text_for_element(inventory_report, 'InternalVendorNumber')
      @supplier = Spree::Supplier.find_by(
        internal_vendor_number: internal_vendor_number,
        edi_identifier: edi_identifier
      )

      puts "EDI Identifier: #{edi_identifier}".yellow

      error = I18n.t(
        'edi.invalid_supplier',
        internal_vendor_number: internal_vendor_number,
        edi_identifier: edi_identifier
      )
      raise error if @supplier.nil?
    end

    def process_inventory
      ro = ResponseObject.success_response_object(nil, {})
      successful = []
      failed = []

      begin
        @doc = Nokogiri::XML(@content)

        inventory_reports = @doc.at_css('InventoryReports').elements

        puts inventory_reports

        puts 'No Inventory Reports Found'.red && return if
            inventory_reports.nil? || inventory_reports.empty?

        inventory_reports.each do |inventory_report|
          # Ensure we have a valid supplier
          begin
            validate_supplier(inventory_report)
          rescue => ex
            puts "Invalid Supplier Found: #{ex}. Moving on.".red
            next
          end

          # TODO: First check to ensure we haven't yet processed this document.
          inventories = inventory_report.css('Detail')
          inventories.each do |inventory_node|
            # puts "#{inventory_node}".yellow
            parse_inventory_node(inventory_node)
            # We first store the reference ASN document.
            # asn = parse_inventory_node(asn_node)
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

    # This is meant to work better with EDI brands or folks updating inventory via
    # FTP
    # For Shopify Brands, we do not expect their inventory to come in via FTP or EDI
    # otherwise we would also need to search for Variant's retailer_assigned_upc

    def parse_inventory_node(inventory_node)
      begin
        quantity_available = parse_text_for_element(inventory_node, 'QuantityAvailableForSale')
        upc = parse_text_for_element(inventory_node, 'UPCCode')

        variants = Spree::Variant.where(upc: upc,
                                        supplier_id: @supplier.id)
        return if variants.empty?

        variants.each do |v|
          v.update_variant_stock(quantity_available)
        end
        puts "Quantity for #{upc} is #{quantity_available}"
      rescue => ex
        puts "Error Parsing Inventory Node: #{ex}".red
      end
    end
  end
end
