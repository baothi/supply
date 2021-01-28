require 'prawn'
class ResellerAgreementPdf < Prawn::Document
  def initialize(supplier = nil, retailer = nil)
    super(top_margin: 70)
    @supplier = supplier
    @retailer = retailer
    create_header
    cover_page
    product_information
    # start_new_page
    # valid_licenses

    create_footer
  end

  def valid_licenses
    text 'Appendix A - Licenses', size: 15
    move_down 40

    text 'Below is a list of the licenses Bioworld Inc. has the legal authority'\
    ' to distribute products for:'
    move_down 40
    text '4Kids Media'
    text 'Activision: Call of Duty'
    text 'Albert Einstein'
    text 'Bethesda: Fall Out'
    text 'Lucas Film: Star Wars'
    text 'Muhammad Ali'
  end

  # header - https://gist.github.com/abhishek77in/4246643

  def create_header
    repeat :all do
      bounding_box [bounds.left, bounds.top + 30], width: bounds.width do
        image "#{Rails.root}/app/pdfs/bioworld-logo.png", height: 20
        # stroke_horizontal_rule
      end
    end
  end

  def create_footer
    repeat :all do
      bounding_box [bounds.left, bounds.bottom + 35], width: bounds.width do
        font 'Helvetica'
        stroke_horizontal_rule
        move_down(5)
        text 'BIOWORLD Merchandising Inc.', size: 10
        # move_down(5)
        text '2111 W. Walnut Hill Lane, Irving, Texas, 75038 | 1 888 831 2138 '\
         '| www.bioworldmerch.com', size: 10
      end
    end
  end

  def cover_page
    move_down 40
    text " #{DateTime.now.strftime('%B %d, %Y')}"
    move_down 10

    text 'To Whom It May Concern,'

    move_down 20

    text 'This letter shall serve for the sole purpose of verification that Bioworld Merchandising,
      the licensed holder, will be handling the sales and distribution via its own application,
      MXED, which will be powered by DiCentral.'

    move_down 20

    text "Attached is a list of products that #{@retailer.name} (#{@retailer.shopify_url})
      has been given permission to sell and distribute on our behalf as an authorized user
      of our application, MXED."

    move_down 20

    text 'If you have any further questions, please contact our Customer Service department
      below.'

    move_down 20
    text 'Best,'
    text 'Customer Service'
    text 'customerservice@mxedapp.com'
  end

  def product_information
    move_down 20
    build_product_list
  end

  def build_product_list
    num_groups = @retailer.product_listings.count % 8

    @retailer.product_listings.find_in_batches(batch_size: 8) do |group|
      puts "Group Size: #{group.count}"
      list = []
      list << ['Image', 'Product Name', 'Valid URLs']
      group.each do |product_listing|
        product = product_listing.product
        next if product.nil?

        image_url = product.images.first.try(:attachment).url(:mini, timestamp: false)
        # TODO: Use Another Image
        next if image_url.nil?

        url = "https://#{@retailer.shopify_url}/products/#{product_listing.shopify_handle}"
        row = [
            {
                image: build_image_url(image_url),
                # position: :center,
                # vposition: :center,
                image_width: 50,
                image_height: 50
            },
            product.name,
            "Base: https://#{@retailer.shopify_url} \n"\
              "Path: /products/#{product_listing.shopify_handle} \n"\
              "Complete Link: <color c='100' m='100' y='0' k='0'<u>"\
              "<link href='#{url}'>Click here</link></u></color> \n"\
              "Shopify Identifier: #{product_listing.shopify_identifier}"
        ]
        list << row
      end

      start_new_page # unless num_groups.negative?

      table list,
            cell_style: { size: 9, text_color: '000000', inline_format: true },
            column_widths: [60, 200, 240]

      num_groups = num_groups - 1
      puts "#{num_groups}"
    end
  end

  def build_image_url(url)
    begin
      url = if Rails.env.development?
              "#{Rails.root}/public#{url}"
            else
              open(url)
            end
    rescue => ex
      puts "Unable to open image due to #{ex}".red
      puts 'Using default image instead'.red
      url = "#{Rails.root}/public/no_image_50_50.png"
    end
    url
  end
end
