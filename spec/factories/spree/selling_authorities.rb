FactoryBot.define do
  factory :spree_selling_authority, class: 'Spree::SellingAuthority' do
    retailer factory: :spree_retailer
    permittable factory: :spree_product
    permission { %i(reject permit).sample }

    factory :permit_selling_authority do
      permission { :permit }
    end

    factory :reject_selling_authority do
      permission { :reject }
    end
  end
end
