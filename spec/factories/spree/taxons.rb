FactoryBot.define do
  factory :spree_taxon, class: Spree::Taxon do
    sequence(:name) { |n| "taxon_#{n}" }
    taxonomy factory: :spree_taxonomy
    parent_id { taxonomy.root.id }

    factory :spree_license_taxon do
      taxonomy { create(:spree_taxonomy, name: 'License') }
    end

    factory :spree_category_taxon do
      taxonomy { create(:spree_taxonomy, name: 'Platform Category') }
    end

    factory :spree_custom_collection_taxon do
      taxonomy { create(:spree_taxonomy, name: 'CustomCollection') }
    end
  end
end
