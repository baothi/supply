require 'spree'
namespace :sample_data do
  desc 'Adds Dropshipper specific data to spree_sample data'
  task load_additional: :environment do
    puts 'Cannot run this in production!' and return if ENV['DROPSHIPPER_ENV'] == 'production'

    # Adding Sample Retailer
    puts 'Creating Retailer user'
    retailer_user = Spree::User.where(
      email: ENV['RETAILER_EMAIL'],
      shopify_url: 'test.myshopify.com'
    ).first_or_create! do |user|
      user.first_name = Faker::Name.first_name
      user.last_name = Faker::Name.last_name
      user.password = 'password'
    end

    puts 'Add Sample Retailer'
    retailer_object = Spree::Retailer.where(name: 'Sample Shopify Store').
                      first_or_create! do |retailer|
      retailer.email = ENV['RETAILER_EMAIL']
      # retailer.vendor_manager_last_name = Faker::Name.last_name
      # retailer.vendor_manager_email = Faker::Internet.email
      # retailer.vendor_manager_sex = Spree::Retailer.vendor_manager_genders.keys.sample.to_s
      # retailer.program_name = Spree::Retailer.dropship_program_names.keys.sample.to_s
    end

    retailer_owner_role = Spree::Role.find_or_create_by(name: Spree::Retailer::RETAILER_OWNER)

    retailer_object.team_members.first_or_create do |team|
      team.user_id = retailer_user.id
      team.role_id = retailer_owner_role.id
    end

    puts 'Creating Supplier user'
    supplier_user = Spree::User.where(
      email: ENV['SUPPLIER_EMAIL'],
      shopify_url: 'test.myshopify.com'
    ).first_or_create! do |user|
      user.first_name = Faker::Name.first_name
      user.last_name = Faker::Name.last_name
      user.password = 'password'
    end

    # Supplier
    supplier_object = Spree::Supplier.where(
      name: Faker::Company.name
    ).first_or_create! do |supplier|
      supplier.name =  Faker::Company.name
      supplier.email = ENV['SUPPLIER_EMAIL']
      supplier.facebook_url = 'http://www.facebook.com/akintunde'
      supplier.instagram_url = 'http://www.instagram.com/akintunde'
      supplier.website = Faker::Internet.url
      supplier.phone_number = Faker::PhoneNumber.phone_number
      supplier.ecommerce_platform = 'shopify'
      supplier.tax_identifier = 'XXXXXXXXX'
      supplier.tax_identifier_type = 'ein'
      # supplier.customer_service_email = Faker::Internet.email
      # supplier.customer_service_full_name = "#{Faker::Name.first_name} #{Faker::Name.last_name}"
      # supplier.customer_service_phone_number = Faker::PhoneNumber.phone_number
    end

    supplier_owner_role = Spree::Role.find_or_create_by(name: Spree::Supplier::SUPPLIER_OWNER)

    supplier_object.team_members.first_or_create do |team|
      team.user_id = supplier_user.id
      team.role_id = supplier_owner_role.id
    end

    puts 'Completed.'
  end

  desc 'Adds Dropshipper specific data to spree_sample data'
  task associate_data: :environment do
    puts 'Cannot run this in production!' and return if ENV['DROPSHIPPER_ENV'] == 'production'

    supplier = Spree::Supplier.first

    retailer = Spree::Retailer.first
    error_msg = 'No retailer found. Please first run $rake sample_data:load_additional first'
    puts error_msg and return if retailer.nil?

    puts 'Associating Products..'
    Spree::Product.all.each do |product|
      # All seed products will be set to the first Supplier.
      product.supplier_id = supplier.id
      product.save!

      # Create Product Listings
      Spree::ProductListing.where(
        product_id: product.id,
        supplier_id: supplier.id,
        retailer_id: retailer.id,
        shopify_identifier: Faker::Code.unique.ean
      ).first_or_create!
    end

    puts 'Associating Variants..'
    Spree::Variant.all.each do |variant|
      # All seed variants will be set to the first Supplier.
      variant.supplier_id = supplier.id
      variant.save!

      # # Create Variant Listings
      # Spree::VariantListing.where(
      #   variant_id: variant.id,
      #   supplier_id: supplier.id,
      #   retailer_id: retailer.id
      # ).first_or_create!
      #
      # # Create related Variant Listing
      # variant_listing = Spree::VariantListing.where(
      #   retailer_id: retailer.id,
      #   supplier_id: supplier.id,
      #   variant_id: variant.id,
      # ).first_or_create! do |vl|
      #   vl.is_online = true
      #   vl.submission_status = 'NOT_SUBMITTED'
      #   vl.style_identifier = variant.sku
      #   vl.assigned_storefront_identifier_at =
      #     Faker::Date.between(15.days.ago, Date.today)
      #   vl.storefront_identifier = Faker::Code.unique.ean
      #   vl.npa_status = 'not_sent'
      #   vl.npa_status_reason = 'N/A'
      # end
    end

    puts 'Completed'
  end

  desc 'Adds Sample Licenses for testing'
  task create_licenses: :environment do
    puts 'Creating Licenses'.yellow

    taxonomy = Spree::Taxonomy.find_or_create_by(name: 'License')
    LICENSES = ['Marvel Comics', 'Nintendo', 'Pokemon', 'Star Wars', 'Suicide Squad',
                'Super Mario', 'Superman', 'TMNT', 'Wonderwoman',
                'X Men', 'Zelda', 'Assassins Creed', 'featured', 'foundmi', 'top-sellers'].freeze
    root_taxon = Spree::Taxon.find_by(name: 'License')

    LICENSES.each do |license|
      puts license
      t = Spree::Taxon.find_or_create_by(name: license, taxonomy: taxonomy)

      folder = "#{Rails.root}/app/assets/images/placeholders/licenses" # Temporary / Fake
      full_path = "#{folder}/wb.jpeg"

      file = File.open(full_path)
      t.outer_banner = file
      t.inner_banner = file

      t.parent_id = root_taxon.id
      t.save
      puts t.inspect
    end
  end

  desc 'Adds Sample Categories for testing'
  task create_categories: :environment do
    puts 'Creating Category Taxonomy/Taxons'.yellow

    category_taxonomy = Spree::Taxonomy.find_or_create_by(name: 'Category')
    CATEGORIES = ['Shirts', 'Socks', 'Caps'].freeze
    root_taxon = Spree::Taxon.find_by(name: 'Category')

    CATEGORIES.each do |category|
      puts category
      t = Spree::Taxon.find_or_create_by(name: category, taxonomy: category_taxonomy)
      t.parent = root_taxon
      t.save
      puts t.inspect
    end
  end

  desc 'Create Sample Supplier'
  task create_supplier: :environment do
    puts 'Cannot run this in production!' and return if ENV['DROPSHIPPER_ENV'] == 'production'

    puts 'Creating Supplier user'
    supplier_user = Spree::User.where(
      email: 'supplier@hingeto.com',
      shopify_url: 'test.myshopify.com'
    ).first_or_create! do |user|
      user.first_name = Faker::Name.first_name
      user.last_name = Faker::Name.last_name
      user.password = 'password'
    end

    # Supplier
    supplier_object = Spree::Supplier.where(
      name: Faker::Company.name
    ).first_or_create! do |supplier|
      supplier.name =  Faker::Company.name
      supplier.email = Faker::Internet.email
      supplier.facebook_url = 'http://www.facebook.com/akintunde'
      supplier.instagram_url = 'http://www.instagram.com/akintunde'
      supplier.website = Faker::Internet.email
      supplier.phone_number = Faker::PhoneNumber.phone_number
      supplier.ecommerce_platform = Spree::SupplierApplication.ecommerce_platforms.keys.sample.to_s
      supplier.commission_type =  Spree::Supplier.commission_types.keys.sample
      supplier.tax_identifier = 'XXXXXXXXX'
      supplier.tax_identifier_type = Spree::SupplierOnboarding.tax_identifier_types.keys.sample.to_s
      supplier.customer_service_email = Faker::Internet.email
      supplier.customer_service_full_name = "#{Faker::Name.first_name} #{Faker::Name.last_name}"
      supplier.customer_service_phone_number = Faker::PhoneNumber.phone_number
    end

    supplier_owner_role = Spree::Role.find_or_create_by(name: Spree::Supplier::SUPPLIER_OWNER)

    supplier_object.team_members.first_or_create do |team|
      team.user_id = supplier_user.id
      team.role_id = supplier_owner_role.id
    end

    Spree::RetailerSetting.where(retailer: Spree::Retailer.first).first_or_create! do |setting|
      setting.need_to_sign_supplier_agreement = true
    end

    puts 'Completed'
  end

  desc 'Create Bioworld Sample Products'
  task create_bio_world_products: :environment do
    product_infos = []
    50.times do |count|
      product_infos << {
          image_url: 'assassin-creed-wallet.jpg',
          name: "Assassin's Creed Canvas Tri-Fold Wallet #{count}",
          price: 12.75,
          shopify_identifier:  Faker::Code.ean
      }
    end

    # Create Option Types
    option_types_attributes = [
        {
            name: 'tshirt-size',
            presentation: 'Size',
            position: 1
        },
        {
            name: 'tshirt-color',
            presentation: 'Color',
            position: 2
        }
    ]

    option_types_attributes.each do |attrs|
      Spree::OptionType.where(attrs).first_or_create!
    end

    size = Spree::OptionType.find_by!(presentation: 'Size')
    color = Spree::OptionType.find_by!(presentation: 'Color')

    option_values_attributes = [
        {
            name: 'Small',
            presentation: 'S',
            position: 1,
            option_type: size
        },
        {
            name: 'Red',
            presentation: 'Red',
            position: 1,
            option_type: color
        }
    ]

    option_values_attributes.each do |attrs|
      Spree::OptionValue.where(attrs).first_or_create!
    end

    # First delete all products
    Spree::Product.delete_all
    Spree::Product.all.each do |product|
      product.deleted_at = Time.now
      product.save!
    end

    product_infos.each do |product_info|
      puts product_info

      # fake_shopify = Faker::Code.ean

      # Initialize
      local_product = Spree::Product.where(
        shopify_identifier: product_info[:shopify_identifier]
      ).first_or_create! do |product|
        product.name = product_info[:name]
        product.shopify_identifier = product_info[:shopify_identifier]
        product.description = Faker::Lorem.paragraph(2)
        product.price = product_info[:price]
        product.available_on = Time.now
        product.shipping_category = Spree::ShippingCategory.first
        product.supplier_id = Spree::Supplier.first.id
      end

      # Update MSRP
      local_product.master.msrp_price = product_info[:price]
      local_product.save

      file_path = "app/assets/images/seed/#{product_info[:image_url]}"

      # Create Image / Asset
      file = File.open(file_path)
      local_product.images.create(
        attachment: file
      )

      # Now create a listing for it
      listing = Spree::ProductListing.where(
        product_id: local_product.id
      ).first_or_create! do |product|
        product.retailer_id = Spree::Retailer.first.id
        product.supplier_id = Spree::Supplier.first.id
        product.shopify_identifier = Faker::Code.ean
      end

      puts "Created: #{listing.inspect}".yellow
      small = Spree::OptionValue.where(name: 'Small').first_or_create
      red = Spree::OptionValue.where(name: 'Red').first_or_create

      local_variant = Spree::Variant.new
      local_variant.product_id = local_product.id
      local_variant.available_on = Time.now
      local_variant.cost_price = local_product.price
      local_variant.msrp_price = local_product.price * 5
      local_variant.msrp_currency = 'USD'
      local_variant.option_values = [small, red]
      local_variant.save!
      local_variant.update_variant_stock(100)
    end
  end

  desc 'Simulate data rake'
  task simulate_order_webhook: :environment do
    @data = File.open(File.join(Rails.root, 'test/fixtures/shopify/order.json'))
    shopify_order = JSON.parse(@data, object_class: OpenStruct)

    @team = Spree::Retailer.first

    job = Spree::LongRunningJob.create(
      action_type: 'import',
      job_type: 'orders_import',
      initiated_by: 'system',
      retailer_id: @team.id,
      teamable_type: 'Spree::Retailer',
      teamable_id: @team.id,
      option_1: 'webhook',
      option_4: shopify_order.id,
      input_data: @data
    )
    ShopifyOrderImportJob.perform_now(job.internal_identifier)
  end

  def create_fake_address
    # Create Address
    addr = Spree::Address.new
    addr.firstname = Faker::Name.first_name
    addr.lastname = Faker::Name.last_name
    addr.business_name = Faker::Company.name
    addr.address1 = Faker::Address.street_address
    addr.city = Faker::Address.city
    addr.zipcode = Faker::Address.zip_code.to_s.slice(0, 5)
    addr.phone = Faker::PhoneNumber.cell_phone

    # Country
    country = Spree::Country.find_by_iso('US')
    addr.country = country
    # States
    state = country.states.first
    addr.state = state
    addr.name_of_state = state.name
    addr
  end

  def nevada_address
    # Create Address
    addr = Spree::Address.new
    addr.firstname = Faker::Name.first_name
    addr.lastname = Faker::Name.last_name
    addr.business_name = Faker::Company.name
    addr.address1 = Faker::Address.street_address # '1467 Valley Street'
    addr.city = 'RUBY VALLEY'
    addr.zipcode = '89833'
    addr.phone = Faker::PhoneNumber.cell_phone
    # Country
    country = Spree::Country.find_by_iso('US')
    addr.country = country
    # States
    state = country.states.find_by_abbr('NV')
    addr.state = state
    addr.name_of_state = state.name
    addr
  end

  def pennsylvania_address
    # Create Address
    addr = Spree::Address.new
    addr.firstname = Faker::Name.first_name
    addr.lastname = Faker::Name.last_name
    addr.business_name = Faker::Company.name
    addr.address1 = Faker::Address.street_address # '946  Badger Pond Lane'
    addr.city = 'Hickory'
    addr.zipcode = '15340'
    addr.phone = Faker::PhoneNumber.cell_phone
    # Country
    country = Spree::Country.find_by_iso('US')
    addr.country = country
    # States
    state = country.states.find_by_abbr('PA')
    addr.state = state
    addr.name_of_state = 'Nevada'
    addr
  end

  desc 'Create Bioworld Sample Orders'
  task create_sample_orders: :environment do
    # Spree::Order.destroy_all

    orders = []
    5.times do |n|
      orders << Spree::Order.where(
        number: Faker::Code.ean,
        email: Faker::Internet.email
      ).first_or_initialize

      unless orders[n].line_items.any?
        orders[n].line_items.new(
          variant: Spree::Product.last.master,
          quantity: 1,
          price: 15.99
        )
      end
    end

    Rails.application.config.spree.stock_splitters =
      [Spree::Stock::Splitter::CustomSplitter]

    # orders.each(&:create_proposed_shipments)

    orders.each do |order|
      order.retailer_shopify_number = Faker::Code.ean
      order.retailer_shopify_name = Faker::Code.ean
      order.retailer_shopify_order_number = 5555

      order.save!

      order.shipping_address = pennsylvania_address
      order.billing_address = pennsylvania_address

      # order.create_proposed_shipments
      order.save!
      order.reload

      order.state = 'complete'
      order.completed_at = Time.current - 1.day
      order.save!

      order.create_proposed_shipments
      order.reload
      order.set_dropshipping_totals!

      # order.find_and_set_most_expensive_shipment!
      # order.set_searchable_attributes

      # order.create_proposed_shipments

      # puts 'create_proposed_shipments'.magenta

      # order.reload
      # order.set_dropshipping_totals!
    end

    # Test

    # create payments based on the totals since they can't be known in YAML (quantities are random)
    method = Spree::PaymentMethod.where(name: 'Credit Card', active: true).first_or_create!

    # Hack the current method so we're able to return a gateway without a RAILS_ENV
    Spree::Gateway.class_eval do
      def self.current
        Spree::Gateway::Bogus.new
      end
    end

    # This table was previously called spree_creditcards, and older migrations
    # reference it as such. Make it explicit here that this table has been renamed.
    Spree::CreditCard.table_name = 'spree_credit_cards'

    credit_card = Spree::CreditCard.where(cc_type: 'visa',
                                          month: 12,
                                          year: 2.years.from_now.year,
                                          last_digits: '1111',
                                          name: 'Sean Schofield',
                                          gateway_customer_profile_id: 'BGS-1234').first_or_create!

    Spree::Order.all.each_with_index do |order, _index|
      order.update_with_updater!
      payment = order.payments.where(amount: BigDecimal(order.total, 4),
                                     source: credit_card.clone,
                                     payment_method: method).first_or_create!

      payment.update_columns(state: 'pending', response_code: '12345')
    end
  end

  desc 'Runs both tasks together'
  task sample_data: ['sample_data:load_additional', 'sample_data:associate_data']
end
