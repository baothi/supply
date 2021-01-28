class Spree::Grouping < ApplicationRecord
  include InternalIdentifiable
  include MiniIdentifiable
  before_validation :build_slug

  has_many :taxon_groupings, dependent: :destroy, class_name: 'Spree::TaxonGrouping'
  has_many :taxons, through: :taxon_groupings, class_name: 'Spree::Taxon'

  enum group_type: { license: 'license' }

  validates :name, :group_type, presence: true
  validates :name, uniqueness: true

  def build_slug
    self.slug = "#{name&.parameterize}-#{mini_identifier}"
  end

  def has_non_zero_taxons_for?(retailer)
    self.taxons.find_each do |taxon|
      return true if taxon.available_products_for_retailer(retailer).count > 0
    end
    false
  end

  def taxons_for(retailer)
    taxons.has_outer_banner.select { |taxon| taxon.available_products_for_retailer(retailer).count > 0}
  end
end
