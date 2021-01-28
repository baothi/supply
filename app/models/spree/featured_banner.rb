class Spree::FeaturedBanner < ApplicationRecord
  include InternalIdentifiable

  belongs_to :taxon, optional: true, class_name: 'Spree::Taxon'

  validates :title, presence: true

  has_attached_file :image, styles: { small: '300x300>', large: '1000x1000>' }
  validates_attachment_content_type :image, content_type: /\Aimage\/.*\Z/

  scope :featured_licenses, -> {
    joins(taxon: :taxonomy).where('spree_taxonomies.name': 'License')
  }
end
