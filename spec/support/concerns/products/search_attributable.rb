RSpec.shared_examples 'a search attributable product model' do
  let :search_attr do
    {
        "available_quantity": 500,
        "eligible_for_international_sale": nil,
        "supplier_internal_identifier": '',
        "supplier_name": '',
        "supplier_brand_name": '',
        "license_taxons": [],
        "category_taxons": [],
        "custom_collection_taxons": [],
        "propercase_name": '',
        "product_variants": []
    }
  end

  describe '#update_search_attributes!' do
    it 'contains all of the correct attributes' do
      product = create(:spree_product)
      product.update_search_attributes!
      expect(product.search_attributes.keys).to match_array search_attr.keys.map(&:to_s)
    end
  end

  describe '#with_search_criteria_eligible_for_intl_sale' do
    before do
      @products = create_list(:spree_product, 4)
    end
    it 'return correct results when eligible_for_intl_sale is true' do
      product = @products.first
      product.update_search_attribute_value!('eligible_for_international_sale', true)
      expect(Spree::Product.with_search_criteria_eligible_for_intl_sale.count).to eq 1
    end
    it 'does returns the right number of eligible_for_intl_sale products under mixed scenarios' do
      first_product = @products.first
      second_product = @products.second
      third_product = @products.third

      first_product.update_search_attribute_value!('eligible_for_international_sale', false)
      second_product.update_search_attribute_value!('eligible_for_international_sale', true)
      third_product.update_search_attribute_value!('eligible_for_international_sale', true)
      expect(Spree::Product.with_search_criteria_eligible_for_intl_sale.count).to eq 2
    end
  end

  describe '#with_search_criteria_stock_gte' do
    before do
      @products = create_list(:spree_product, 3)
    end
    it 'returns the right number of products' do
      first_product = @products.first
      second_product = @products.second
      third_product = @products.third

      first_product.update_search_attribute_value!('available_quantity', 100)
      second_product.update_search_attribute_value!('available_quantity', 0)
      third_product.update_search_attribute_value!('available_quantity', -1)

      expect(Spree::Product.with_search_criteria_stock_gte(0).count).to eq 2
      expect(Spree::Product.with_search_criteria_stock_gte(50).count).to eq 1
      expect(Spree::Product.with_search_criteria_stock_gte(-5).count).to eq 3
    end
  end

  describe '#with_search_criteria_stock_lte' do
    before do
      @products = create_list(:spree_product, 3)
    end
    it 'returns the right number of products' do
      first_product = @products.first
      second_product = @products.second
      third_product = @products.third

      first_product.update_search_attribute_value!('available_quantity', 100)
      second_product.update_search_attribute_value!('available_quantity', 0)
      third_product.update_search_attribute_value!('available_quantity', -1)

      expect(Spree::Product.with_search_criteria_stock_lte(0).count).to eq 2
      expect(Spree::Product.with_search_criteria_stock_lte(50).count).to eq 2
      expect(Spree::Product.with_search_criteria_stock_lte(-5).count).to eq 0
    end
  end

  describe '#with_search_criteria_category_taxon_id' do
    before do
      @products = create_list(:spree_product, 4)
    end

    it 'filters the correct list of categories' do
      category_json1 = [
          {
          "id": 2,
          "name": 'Accessories'
        },
          {
              "id": 3,
              "name": 'Watches'
          }
      ]

      category_json2 = [
          {
              "id": 3,
              "name": 'Watches'
          }
      ]

      first_product = @products.first
      second_product = @products.second

      first_product.update_search_attribute_value!('category_taxons', category_json1)
      second_product.update_search_attribute_value!('category_taxons', category_json2)

      expect(Spree::Product.with_search_criteria_category_taxon_id(3).count).to eq 2
      expect(Spree::Product.with_search_criteria_category_taxon_id(2).first).to eq first_product
      expect(Spree::Product.with_search_criteria_category_taxon_id(5).count).to eq 0
    end
  end

  describe '#with_search_criteria_eligible_for_intl_sale' do
    before do
      @products = create_list(:spree_product, 4)
    end

    it 'does returns the right number of eligible_for_intl_sale products under mixed scenarios' do
      first_product = @products.first
      second_product = @products.second
      third_product = @products.third

      first_product.update_search_attribute_value!('eligible_for_international_sale', false)
      second_product.update_search_attribute_value!('eligible_for_international_sale', true)
      third_product.update_search_attribute_value!('eligible_for_international_sale', true)
      expect(Spree::Product.with_search_criteria_eligible_for_intl_sale.count).to eq 2
    end
  end

  describe '#with_search_criteria_license_taxon_id' do
    before do
      @products = create_list(:spree_product, 4)
    end

    it 'filters the correct list of licenses' do
      license_json1 = [
          {
          "id": 23,
          "name": 'Marvel'
        },
          {
              "id": 31,
              "name": 'DC Comics'
          }
      ]

      license_json2 = [
          {
              "id": 31,
              "name": 'DC Comics'
          }
      ]

      license_json3 = [
          {
              "id": 45,
              "name": 'Simpsons'
          }
      ]

      first_product = @products.first
      second_product = @products.second
      third_product = @products.third

      first_product.update_search_attribute_value!('license_taxons', license_json1)
      second_product.update_search_attribute_value!('license_taxons', license_json2)
      third_product.update_search_attribute_value!('license_taxons', license_json3)

      expect(Spree::Product.with_search_criteria_license_taxon_id(31).count).to eq 2
      expect(Spree::Product.with_search_criteria_license_taxon_id(45).first).to eq third_product
      expect(Spree::Product.with_search_criteria_license_taxon_id(46).count).to eq 0
    end
  end
end
