class Spree::TaxonGrouping < ApplicationRecord
  belongs_to :taxon, class_name: 'Spree::Taxon'
  belongs_to :grouping, class_name: 'Spree::Grouping'

  validates :taxon, :grouping, presence: true
  validates :taxon, uniqueness: { scope: :grouping_id, message: 'already exists in this grouping' }
end
