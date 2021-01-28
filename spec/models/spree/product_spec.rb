require 'rails_helper'

RSpec.describe Spree::Product, type: :model do
  subject { build(:spree_product) }

  before do
    Mongoid.purge!
  end

  it_behaves_like 'an internal_identifiable model'
  it_behaves_like 'a search attributable product model'

  describe 'Model from Factory' do
    it { is_expected.to be_valid }

    context 'when any of the required fields is nil' do
      it { expect(build(:spree_product, name: nil)).not_to be_valid }
      it { expect { create(:spree_product, price: nil) }.to raise_error RuntimeError }
      it { expect(build(:spree_product, shipping_category: nil)).not_to be_valid }
    end
  end

  describe 'Model Association' do
    it do
      expect(subject).to have_many(:selling_authorities).dependent(:destroy)
    end

    it do
      expect(subject).to have_many(:permit_selling_authorities).conditions(permission: :permit).
        class_name('Spree::SellingAuthority')
    end

    it do
      expect(subject).to have_many(:reject_selling_authorities).conditions(permission: :reject).
        class_name('Spree::SellingAuthority')
    end

    it do
      expect(subject).to have_many(:white_listed_retailers).through(:permit_selling_authorities).
        source(:retailer)
    end

    it do
      expect(subject).to have_many(:black_listed_retailers).through(:reject_selling_authorities).
        source(:retailer)
    end
  end

  describe 'Active model validation' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:shipping_category) }
  end

  describe '#commission_from_dropshipping' do
    let(:price_diff) { subject.master.msrp_price.to_f - subject.master.price.to_f }

    it 'returns difference between product msrp_price and product cost_price' do
      expect(subject.commission_from_dropshipping).to eql price_diff
    end

    context 'when product has no master variant' do
      before { subject.master = nil }

      it 'returns 0' do
        expect(subject.commission_from_dropshipping).to be_zero
      end
    end
  end

  describe 'scopes' do
    before do
      @products = create_list(:spree_product, 5)
    end

    describe '.by_supplier' do
      context 'when products by given supplier does NOT exist' do
        it 'returns empty when product for given supplier is not found' do
          expect(Spree::Product.by_supplier(-1)).to be_empty
        end
      end

      context 'when product by given supplier exists' do
        let(:supplier) { create(:spree_supplier) }
        let(:product) { create(:spree_product, supplier: supplier) }

        before do
          create_list(:spree_product, 2, supplier: supplier)
        end

        it 'returns as many products as is available for the given supplier' do
          expect(Spree::Product.by_supplier(supplier.id).count).to be 2
        end

        it 'return products collection that include the "product"' do
          expect(Spree::Product.by_supplier(supplier.id)).to include product
        end
      end
    end

    describe 'from_created' do
      let(:product) { create(:spree_product, created_at: 2.years.from_now) }

      before do
        create_list(:spree_product, 2, created_at: 2.years.from_now)
      end

      it 'selects products with created from the date given upwards' do
        expect(Spree::Product.from_created(1.year.from_now).count).to be 2
      end

      it 'includes "product" in the selection' do
        expect(Spree::Product.from_created(1.year.from_now)).to include product
      end
    end

    describe 'to_created' do
      let(:product) { create(:spree_product, created_at: 2.years.ago) }

      before do
        create_list(:spree_product, 2, created_at: 2.years.ago)
      end

      it 'selects products with created from the date given upwards' do
        expect(Spree::Product.to_created(1.year.ago).count).to be 2
      end

      it 'includes "product" in the selection' do
        expect(Spree::Product.to_created(1.year.ago)).to include product
      end
    end

    describe '.in_multiple_taxons' do
      before do
        license_taxonomy = create(:taxonomy, name: 'License')
        category_taxonomy = create(:taxonomy, name: 'Platform Category')
        @license_taxon = create(:taxon, taxonomy: license_taxonomy)
        @category_taxon = create(:taxon, taxonomy: category_taxonomy)

        # set license and category taxons on first and second products
        @first_product, @second_product = @products.first(2)
        @first_product.taxons << @license_taxon
        @first_product.taxons << @category_taxon

        @second_product.taxons << @license_taxon
        @second_product.taxons << @category_taxon
      end

      it 'returns 2 taxons' do
        expect(Spree::Product.in_multiple_taxons(@license_taxon, @category_taxon).count).to be 2
      end

      it 'includes the "@first_product" and "@second_product" in the response' do
        result = Spree::Product.in_multiple_taxons(@license_taxon, @category_taxon)
        expect(result).to include @first_product
        expect(result).to include @second_product
      end
    end

    describe '#image_attachment_urls' do
      it 'returns an empty array if there are no images' do
        product = build(:spree_product)

        expect(product.image_attachment_urls).to eq []
      end

      it 'returns an array of 10 images if there are more than 10 images' do
        product = create(:spree_product, images: create_list(:spree_image, 12))

        expect(product.image_attachment_urls.size).to eq 10
      end
    end

    describe '.has_permit_selling_authority' do
      context 'when NO product has permit authority' do
        before do
          Spree::SellingAuthority.destroy_all
        end

        it 'returns an empty array' do
          expect(Spree::Product.has_permit_selling_authority).to be_an ActiveRecord::Relation
          expect(Spree::Product.has_permit_selling_authority).to be_empty
        end
      end

      context 'when permit selling authority is set on some products' do
        let(:product1) { @products.first }
        let(:product2) { @products.second }
        let(:product3) { @products.third }

        before do
          create :permit_selling_authority, permittable: product1
          create :permit_selling_authority, permittable: product2
        end

        it 'does NOT return empty array' do
          expect(Spree::Product.has_permit_selling_authority).not_to be_empty
        end

        it 'contains product1 and product2' do
          expect(Spree::Product.has_permit_selling_authority).to include product1
          expect(Spree::Product.has_permit_selling_authority).to include product2
        end

        it 'does NOT include product3' do
          expect(Spree::Product.has_permit_selling_authority).not_to include product3
        end
      end
    end

    describe '.has_reject_selling_authority' do
      context 'when NO product has permit authority' do
        before do
          Spree::SellingAuthority.destroy_all
        end

        it 'returns an empty array' do
          expect(Spree::Product.has_reject_selling_authority).to be_an ActiveRecord::Relation
          expect(Spree::Product.has_reject_selling_authority).to be_empty
        end
      end

      context 'when permit selling authority is set on some products' do
        let(:product1) { @products.first }
        let(:product2) { @products.second }
        let(:product3) { @products.third }

        before do
          create :reject_selling_authority, permittable: product1
          create :reject_selling_authority, permittable: product2
        end

        it 'does NOT return empty array' do
          expect(Spree::Product.has_reject_selling_authority).not_to be_empty
        end

        it 'contains product1 and product2' do
          expect(Spree::Product.has_reject_selling_authority).to include product1
          expect(Spree::Product.has_reject_selling_authority).to include product2
        end

        it 'does NOT include product3' do
          expect(Spree::Product.has_reject_selling_authority).not_to include product3
        end
      end
    end
  end

  describe 'Instant methods' do
    describe '#license_taxons' do
      before do
        random_taxon = create(:spree_taxon)
        subject.taxons << random_taxon
        subject.save
      end

      context 'when the product does not have license taxons' do
        it 'returns an empty array' do
          expect(subject.license_taxons).to be_an Array
          expect(subject.license_taxons).to be_empty
        end
      end

      context 'when the product has taxons' do
        before do
          license_taxons = create_list(:spree_license_taxon, 3)
          subject.taxons << license_taxons
          subject.save
        end

        it 'returns an array of 3 hashes' do
          expect(subject.license_taxons).to be_an Array
          expect(subject.license_taxons.first).to be_an Hash
          expect(subject.license_taxons.count).to be 3
        end

        it 'contains "id" and "name" keys in hashes' do
          expect(subject.license_taxons.first).to have_key :id
          expect(subject.license_taxons.first).to have_key :name
        end
      end
    end

    describe '#category_taxons' do
      before do
        random_taxon = create(:spree_taxon)
        subject.taxons << random_taxon
        subject.save
      end

      context 'when the product does not have license taxons' do
        it 'returns an empty array' do
          expect(subject.category_taxons).to be_an Array
          expect(subject.category_taxons).to be_empty
        end
      end

      context 'when the product has taxons' do
        before do
          category_taxons = create_list(:spree_category_taxon, 3)
          subject.taxons << category_taxons
          subject.save
        end

        it 'returns an array of 3 hashes' do
          expect(subject.category_taxons).to be_an Array
          expect(subject.category_taxons.first).to be_an Hash
          expect(subject.category_taxons.count).to be 3
        end

        it 'contains "id" and "name" keys in hashes' do
          expect(subject.category_taxons.first).to have_key :id
          expect(subject.category_taxons.first).to have_key :name
        end
      end
    end

    describe '#custom_collection_taxons' do
      before do
        random_taxon = create(:spree_taxon)
        subject.taxons << random_taxon
        subject.save
      end

      context 'when the product does not have license taxons' do
        it 'returns an empty array' do
          expect(subject.custom_collection_taxons).to be_an Array
          expect(subject.custom_collection_taxons).to be_empty
        end
      end

      context 'when the product has taxons' do
        before do
          custom_collection_taxons = create_list(:spree_custom_collection_taxon, 3)
          subject.taxons << custom_collection_taxons
          subject.save
        end

        it 'returns an array of 3 hashes' do
          expect(subject.custom_collection_taxons).to be_an Array
          expect(subject.custom_collection_taxons.first).to be_an Hash
          expect(subject.custom_collection_taxons.count).to be 3
        end

        it 'contains "id" and "name" keys in hashes' do
          expect(subject.custom_collection_taxons.first).to have_key :id
          expect(subject.custom_collection_taxons.first).to have_key :name
        end
      end
    end

    describe '.unpublish_unavailable' do
      let!(:products) { create_list(:spree_product_in_stock, 5) }

      context 'no unavailable products' do
        it 'returns nil' do
          expect(Spree::Product.unpublish_unavailable).to eq nil
        end

        it 'does not call unpublish' do
          expect_any_instance_of(Spree::Product).not_to receive(:unpublish)
          Spree::Product.unpublish_unavailable
        end
      end

      context 'when unavailable products exists' do
        it 'calls unpublish for unavailable products' do
          products.first.update(discontinue_on: Time.now)

          expect_any_instance_of(Spree::Product).to receive(:unpublish)
          Spree::Product.unpublish_unavailable
        end
      end
    end

    describe '#unpublish' do
      before do
        ActiveJob::Base.queue_adapter = :test
      end

      context 'product is unavailable' do
        it 'enqeues live unpublish job' do
          subject.update(discontinue_on: Time.now)
          expect { subject.unpublish }.to enqueue_job(Shopify::UnpublishJob)
        end
      end

      context 'product is available' do
        it 'returns nil' do
          expect(subject.unpublish).to be nil
        end
      end

      it 'does not enqeue unpublish job' do
        expect { subject.unpublish }.not_to enqueue_job(Shopify::UnpublishJob)
      end

      context 'when product has no master variant' do
        before { subject.master = nil }

        it 'returns 0' do
          expect(subject.commission_from_dropshipping).to be_zero
        end
      end
    end

    describe '#stock_quantity' do
      let(:spree_product_in_stock) { create(:spree_product_in_stock) }

      before do
        allow(spree_product_in_stock).to receive(:valid_count_on_hand).and_return(5)
      end

      context 'product discontinuation' do
        before do
          spree_product_in_stock.available_on = DateTime.now
        end

        # This is no longer expected behaviour
        # it 'returns 0' do
        #   spree_product_in_stock.discontinue_on = DateTime.now
        #   expect(spree_product_in_stock.stock_quantity).to eq 0
        # end

        it 'does not return zero when products are not discontinued' do
          spree_product_in_stock.discontinue_on = nil
          expect(spree_product_in_stock.stock_quantity).not_to eq 0
        end
      end

      # context 'product availability' do
      #   before do
      #     spree_product_in_stock.discontinue_on = nil
      #   end
      #   it 'returns zero when product is not available' do
      #     spree_product_in_stock.available_on = nil
      #     spree_product_in_stock.discontinue_on = nil
      #     expect(spree_product_in_stock.stock_quantity).to eq 0
      #   end
      #   it 'does not return zero when products are available ' do
      #     spree_product_in_stock.available_on = DateTime.now
      #     spree_product_in_stock.discontinue_on = nil
      #     expect(spree_product_in_stock.stock_quantity).not_to eq 0
      #   end
      # end
    end
  end

  describe '#last_five_internal_identifier' do
    context 'when the products has no internal identifier' do
      it 'returns nil' do
        expect(subject.last_five_internal_identifier).to be_nil
      end
    end

    context 'when the product has an internal identifier' do
      it 'returns the last five characters of its internal_identifier' do
        product = create(:spree_product)

        expect(product.last_five_internal_identifier).to eq product.internal_identifier[-5..-1]
      end
    end
  end

  describe '#shopify_params' do
    it 'returns a hash' do
      expect(subject.shopify_params(spree_retailer)).to be_a Hash
    end
  end

  describe '#shopify_image_urls_param' do
    it 'returns array of image urls' do
      expect(subject.shopify_image_urls_param).to be_a Array
    end
  end

  describe '#price_based_on_retailer' do
    before do
      allow(subject).to receive_message_chain(:variants, :map) { [10, 30, 25] }
    end

    it 'returns an integer value' do
      expect(subject.price_based_on_retailer(spree_retailer)).to be_a Numeric
    end

    it 'returns the highest number' do
      expect(subject.price_based_on_retailer(spree_retailer)).to be 30
    end

    context 'when some variants has no master_cost' do
      before do
        allow(subject).to receive_message_chain(:variants, :map) { [10, nil, 30, 25, nil] }
      end

      it 'returns the highest number' do
        expect(subject.price_based_on_retailer(spree_retailer)).to be 30
      end
    end
  end

  describe 'callbacks' do
    it 'runs the mark_cache_as_deleted callback' do
      product = create(:spree_product_in_stock)
      expect(product).to receive(:mark_cache_as_deleted!)
      product.run_callbacks(:destroy)
    end
  end

  describe '#mark_cache_as_deleted!' do
    it 'finds the right shopify cached product and marks it as deleted' do
      shopify_cache_product = create(:shopify_cache_product,
                                     shopify_url: spree_supplier.shopify_url)
      shopify_id = shopify_cache_product.id

      spree_product = create(:spree_product_in_stock, supplier: spree_supplier,
                                                      shopify_identifier: shopify_id)

      expect(ShopifyCache::Product.find(shopify_id)).not_to be_nil
      spree_product.destroy

      expect(ShopifyCache::Product.find(shopify_id)).to be_nil
    end
  end
end
