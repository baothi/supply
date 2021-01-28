FactoryBot.define do
  factory :spree_taxon_grouping, class: 'Spree::TaxonGrouping' do
    taxon factory: :spree_taxon
    grouping factory: :spree_grouping
  end
end
