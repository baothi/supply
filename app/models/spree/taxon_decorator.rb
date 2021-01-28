Spree::Taxon.class_eval do
  include MiniIdentifiable
  before_validation :build_slug

  belongs_to :supplier, class_name: 'Spree::Supplier'
  belongs_to :retailer, class_name: 'Spree::Retailer'

  require 'open-uri'
  acts_as_followable

  scope :is_license, -> {
    joins(:taxonomy).
      where('spree_taxonomies.name': 'License').
      where.not('spree_taxons.name': 'License')
  }

  scope :is_category, -> {
    joins(:taxonomy).
      where('spree_taxonomies.name': 'Platform Category').
      where.not('spree_taxons.name': 'Platform Category')
  }

  scope :is_custom_collection, -> {
    joins(:taxonomy).
      where('spree_taxonomies.name': 'CustomCollection').
      where.not('spree_taxons.name': 'CustomCollection')
  }

  # scope :is_supplier_category, -> {
  #   joins(:taxonomy).
  #       where('spree_taxonomies.name': 'Supplier Category').
  #       where.not('spree_taxons.supplier_id': [nil, ""]).
  #       where.not('spree_taxons.name': 'Supplier Category')
  # }
  #
  # scope :is_retailer_category, -> {
  #   joins(:taxonomy).
  #       where('spree_taxonomies.name': 'Retailer Category').
  #       where.not('spree_taxons.retailer_id': [nil, ""]).
  #       where.not('spree_taxons.name': 'Retailer Category')
  # }

  scope :has_outer_banner, -> {
    where.not(outer_banner_file_name: nil)
  }

  scope :does_not_have_outer_banner, -> {
    where(outer_banner_file_name: nil)
  }

  scope :has_inner_banner, -> {
    where.not(inner_banner_file_name: nil)
  }

  scope :license_without_outer_banner, -> {
    is_license.does_not_have_outer_banner
  }

  scope :other_licenses_not_in_group, -> {
    is_license.where.not(id: Spree::TaxonGrouping.select(:taxon_id))
  }

  has_attached_file :inner_banner,
                    styles: {
                        thumb: '100x100>',
                        main: '500x500>',
                        square: '500x500#'
                    },
                    default_url: ENV['DEFAULT_PHOTO']
  validates_attachment_content_type :inner_banner,
                                    content_type: /\Aimage\/.*\Z/

  has_attached_file :outer_banner,
                    styles: {
                        thumb: '100x100>',
                        main: '500x500>',
                        square: '500x500#'
                    },
                    default_url: ENV['DEFAULT_PHOTO']
  validates_attachment_content_type :outer_banner, content_type: /\Aimage\/.*\Z/

  def self.default_scope
    where(deleted_at: nil)
  end

  def friendly_name
    display_name || name
  end

  def banner_from_url(url)
    self.inner_banner = open(url)
    self.outer_banner = open(url)
  end

  def banner_from_url!(url)
    self.inner_banner = open(url)
    self.outer_banner = open(url)
    self.save
  end

  def license?
    self.taxonomy.name == 'License'
  end

  def category?
    self.taxonomy.name == 'Platform Category'
  end

  def custom_collection?
    self.taxonomy.name == 'CustomCollection'
  end

  def approve_all_products!
    puts "Approving all products in #{self.name}".yellow
    self.products.each do |p|
      begin
        p.skip_middle_steps_and_approve!
      rescue => ex
        puts "#{ex}".red
      end
    end
    puts "Finished approving all products in #{self.name}".yellow
  end

  def reject_all_products!
    puts "Rejecting all products in #{self.name}".yellow
    self.products.each do |p|
      begin
        p.skip_middle_steps_and_reject!
      rescue => ex
        puts "#{ex}".red
      end
    end
    puts "Finished rejecting all products in #{self.name}".yellow
  end

  def build_slug
    self.slug = "#{name&.parameterize}-#{mini_identifier}"
  end

  def to_param
    self.slug
  end

  def available_products_for_retailer(retailer)
    return nil if retailer.nil?

    available = Spree::Product.where(supplier_id: retailer.white_listed_suppliers.pluck(:id))
    available = products.merge(available)
    available.marketplace_compliant_and_approved
  end
end
