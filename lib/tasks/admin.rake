require 'spree'
namespace :admin do
  def collect_supplier_email
    puts 'What email address would you like to use:'.blue
    loop do
      supplier_owner_email = Dropshipper::CommandLineHelper.get_input
      supplier_user = Spree::User.where(email: supplier_owner_email).first

      return supplier_owner_email  if supplier_user.nil?

      puts "The email #{supplier_owner_email} is already taken. Please use another: ".red
    end
  end

  def collect_retailer_id
    loop do
      puts 'What retailer is this supplier for? Enter numerical ID representing retailer'.blue
      Spree::Retailer.all.each_with_index do |retailer, _index|
        puts "[#{retailer.id}] - #{retailer.name}".yellow
      end
      retailer_id = Dropshipper::CommandLineHelper.get_input
      retailer = Spree::Retailer.where(id: retailer_id.to_i).first

      return retailer.id if retailer.present?

      puts 'You have selected an invalid retailer. Please try again.'.red
    end
  end

  def collect_supplier_name
    loop do
      puts 'What would you like to name the supplier: '.blue
      supplier_name = Dropshipper::CommandLineHelper.get_input
      supplier = Spree::Supplier.where(name: supplier_name).first
      return supplier_name if supplier.nil?

      puts 'A supplier with this name already exists. Please select another.'.red
    end
  end

  def collect_string(prompt)
    loop do
      puts "#{prompt}".blue
      supplier_name = Dropshipper::CommandLineHelper.get_input
      supplier = Spree::Supplier.where(name: supplier_name).first
      return supplier_name if supplier.nil?

      puts 'A supplier with this name already exists. Please select another.'.red
    end
  end

  def create_supplier(opts = {})
    puts 'Creating Supplier'.yellow
    supplier = Spree::Supplier.new
    supplier.name =  opts[:supplier_name]
    supplier.email = opts[:supplier_email]
    supplier.facebook_url = opts[:facebook_url]
    supplier.instagram_url = opts[:instagram_url]
    supplier.website = opts[:website]
    supplier.phone_number = opts[:phone_number]
    supplier.ecommerce_platform = opts[:ecommerce_platform]
    supplier.commission_type =  opts[:commission_type]
    supplier.tax_identifier = opts[:tax_identifier]
    supplier.tax_identifier_type = opts[:tax_identifier_type]
    supplier.customer_service_email = opts[:supplier_email]
    supplier.customer_service_full_name = "#{opts[:first_name]} #{opts[:last_name]}"
    supplier.customer_service_phone_number = opts[:phone_number]
    supplier.supplier_application_id = opts[:supplier_application_id]
    supplier.supplier_onboarding_id = opts[:supplier_onboarding_id]
    supplier.save!
    supplier
  end

  def create_supplier_application(opts = {})
    puts 'Creating Supplier Application'.yellow
    supplier_application = Spree::SupplierApplication.new
    supplier_application.retailer_id = opts[:retailer_id]
    supplier_application.supplier_name = opts[:supplier_name]
    supplier_application.first_name = opts[:first_name]
    supplier_application.last_name = opts[:last_name]
    supplier_application.email = opts[:supplier_email]
    supplier_application.facebook_url = opts[:facebook_url]
    supplier_application.instagram_url = opts[:instagram_url]
    supplier_application.website = opts[:website]
    supplier_application.phone_number = opts[:phone_number]
    supplier_application.ecommerce_platform = opts[:ecommerce_platform]
    supplier_application.save!
    supplier_application
  end

  def create_supplier_onboarding(opts = {})
    puts 'Creating Supplier Onboarding'.yellow
    onboarding = Spree::SupplierOnboarding.new
    onboarding.retailer_id = opts[:retailer_id]
    onboarding.supplier_application_id = opts[:supplier_application_id]
    onboarding.tax_identifier = opts[:tax_identifier]
    onboarding.tax_identifier_type = opts[:tax_identifier_type]
    onboarding.customer_service_email = opts[:supplier_email]
    onboarding.customer_service_full_name = "#{opts[:first_name]} #{opts[:last_name]}"
    onboarding.customer_service_phone_number = opts[:phone_number]
    onboarding.save!
    onboarding
  end

  def create_supplier_user(opts = {})
    puts 'Creating Supplier User'.yellow
    supplier_user = Spree::User.where(
      email: opts[:supplier_email],
      shopify_url: 'test.myshopify.com'
    ).first_or_create! do |user|
      user.first_name = opts[:first_name]
      user.last_name = opts[:last_name]
      user.password = opts[:supplier_password]
    end
    supplier_user
  end

  desc 'Adds Dropshipper specific data to spree_sample data'
  task create_supplier: :environment do
    puts 'You are in production!'.red if ENV['DROPSHIPPER_ENV'] == 'production'

    puts '=========================='.magenta
    puts '| Supplier Creation Mode |'.magenta
    puts '=========================='.magenta

    # puts 'What would you like to name the supplier?'.blue
    # supplier_name = Dropshipper::CommandLineHelper.get_input

    supplier_name = collect_supplier_name
    first_name = collect_string('What is the supplier owners first name')
    last_name = collect_string('What is the supplier owners last name')
    phone_number = collect_string('What is the supplier owners phone number')
    website = collect_string('What is the supplier\'s website')
    supplier_email = collect_supplier_email
    supplier_password =
      collect_string('What password would you like to use? Needs to be at least 6 characters')
    retailer_id = collect_retailer_id

    opts = {}
    opts[:supplier_name] = supplier_name
    opts[:supplier_email] = supplier_email
    opts[:supplier_password] = supplier_password
    opts[:first_name] = first_name
    opts[:last_name] = last_name
    opts[:email] = supplier_email
    opts[:website] = website
    opts[:phone_number] = phone_number
    opts[:ecommerce_platform] = Spree::SupplierApplication.ecommerce_platforms['Other']
    opts[:commission_type] = Spree::Supplier.commission_types['revenue_share_basis']
    opts[:tax_identifier_type] = Spree::SupplierOnboarding.tax_identifier_types['ein']
    opts[:tax_identifier] = 'XX-XXXXXXX'
    opts[:retailer_id] = retailer_id
    opts[:instagram_url] = 'http://www.instagram.com/xxxxxx'
    opts[:facebook_url] = 'http://www.facebook.com/xxxxxx'

    retailer = Spree::Retailer.find(retailer_id)

    # Supplier Application
    supplier_application = create_supplier_application(opts)
    opts[:supplier_application_id] = supplier_application.id

    # Supplier Onboarding
    supplier_onboarding = create_supplier_onboarding(opts)
    opts[:supplier_onboarding_id] = supplier_onboarding.id

    # Create Supplier User
    supplier_user = create_supplier_user(opts)

    # Create Supplier
    supplier = create_supplier(opts)

    supplier_owner_role = Spree::Role.find_or_create_by(name: Spree::Supplier::SUPPLIER_OWNER)

    supplier.team_members.first_or_create do |team|
      team.user_id = supplier_user.id
      team.role_id = supplier_owner_role.id
    end

    Spree::RetailerSetting.where(retailer: retailer).first_or_create! do |setting|
      setting.need_to_sign_supplier_agreement = false
    end

    puts 'Supplier successfully created!'.green
    puts "Supplier Name: #{supplier_name}".blue
    puts "Supplier Slug: #{supplier.slug}".blue
    puts "Supplier Owner Email: #{supplier_email}".blue
    puts "Supplier Owner First Name: #{first_name}".blue
    puts "Supplier Owner Last Name: #{last_name}".blue
  end

  def create_taxon(taxonomy, root_taxon, license, prop, full_path = nil)
    t = Spree::Taxon.find_or_create_by(name: license, taxonomy: taxonomy)
    t.parent_id = root_taxon.id

    unless full_path.nil?
      file = File.open(full_path)
      if prop == 'outer_banner'
        t.outer_banner = file
      elsif prop == 'inner_banner'
        t.inner_banner = file
      end
    end

    t.save
    puts t.inspect
  end

  def iterate_through_folders_and_create_banners(folder, entries, prop)
    taxonomy = Spree::Taxonomy.find_or_create_by(name: 'License')
    root_taxon = Spree::Taxon.find_by(name: 'License')

    entries.each do |entry|
      next if ['.', '..'].include?(entry)

      full_path = "#{folder}/#{entry}"
      license_name = entry[0..entry.length - 5]
      puts "License Name: #{license_name}"
      create_taxon(taxonomy, root_taxon, license_name, prop, full_path)
    end
  end

  desc 'Seeds the banner license images'
  task upload_license_banners: :environment do
    # Spree::Taxonomy.destroy_all
    # Spree::Taxon.destroy_all

    # Inner Banners
    folder = "#{Rails.root}/app/assets/images/licenses/inner_banners/"
    entries = Dir.entries(folder)

    iterate_through_folders_and_create_banners(folder, entries, 'inner_banner')

    # Outer Banners
    folder = "#{Rails.root}/app/assets/images/licenses/outer_banners/"
    entries = Dir.entries(folder)

    iterate_through_folders_and_create_banners(folder, entries, 'outer_banner')
  end

  desc 'Missing Licenses'
  task missing_banners: :environment do
    Spree::Taxon.all.each do |tax|
      unless tax.inner_banner.exists?
        puts "[Inner Banner] #{tax.name}".red
      end

      unless tax.outer_banner.exists?
        puts "[Outer Banner] #{tax.name}".red
      end
    end
  end
end
