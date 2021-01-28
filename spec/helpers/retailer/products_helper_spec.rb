require 'rails_helper'

RSpec.describe Retailer::ProductsHelper, type: :helper do
  describe '#taxon_list_smart_link' do
    context 'when taxon is a license' do
      let(:taxon) do
        taxonomy = create(:taxonomy, name: 'License')
        create(:taxon, taxonomy: taxonomy)
      end

      it 'returns link to list products by license page' do
        expect(taxon_list_smart_link(taxon)).to eql(
          retailer_list_products_by_license_path(taxon.name)
        )
      end
    end

    context 'when taxon is a category' do
      let(:taxon) do
        taxonomy = create(:taxonomy, name: 'Category')
        create(:taxon, taxonomy: taxonomy)
      end
    end

    context 'when taxon is custom_featured?' do
      let(:taxon) do
        taxonomy = create(:taxonomy, name: 'CustomCollection')
        create(:taxon, taxonomy: taxonomy)
      end

      let(:banner_id) { '1234567890' }

      it 'returns link to product listing by custom feature' do
        expect(taxon_list_smart_link(taxon, banner_id)).to eql(
          retailer_list_products_by_custom_collection_path(
            taxon.name, banner: banner_id
          )
        )
      end
    end

    context 'when taxon is neither license nor category nor custom_collection?' do
      let(:taxon) do
        create(:taxon)
      end

      it 'returns "#"' do
        expect(taxon_list_smart_link(taxon)).to eql '#'
      end
    end
  end

  describe '#featured_banner_link' do
    let(:banner) { create(:spree_featured_banner) }

    it 'calls the taxon_list_smart_link method' do
      expect_any_instance_of(Retailer::ProductsHelper).to(
        receive(:taxon_list_smart_link).with(banner.taxon, banner.internal_identifier)
      )
      featured_banner_link(banner)
    end
  end

  describe '#outer_banner_or_image_placeholder' do
    context 'when taxon has outer_banner' do
      let(:taxon) do
        create(
          :spree_taxon,
          outer_banner: File.open(Rails.root.join('app/assets/images/noimage/large.png'))
        )
      end

      it 'returns image path of the outer_banner attachment' do
        expect(outer_banner_or_image_placeholder(taxon)).to eql taxon.outer_banner
      end

      it 'does not call the "image_placeholder" method' do
        expect_any_instance_of(Retailer::ProductsHelper).not_to receive(:image_placeholder)
        outer_banner_or_image_placeholder(taxon)
      end
    end

    context 'when taxon does NOT have outer_banner attachment' do
      let(:taxon) { create(:spree_taxon) }

      it 'calls the "image_placeholder" method with taxon name' do
        expect_any_instance_of(Retailer::ProductsHelper).to(
          receive(:image_placeholder)
        )
        outer_banner_or_image_placeholder(taxon)
      end
    end
  end

  describe '#image_placeholder' do
    let(:text) { 'Some Text' }

    it 'contains image_placeholder URL string' do
      expect(image_placeholder).to include 'noimage'
    end
  end

  describe '#taxon_or_banner_image' do
    let(:taxon) do
      create(
        :spree_taxon,
        inner_banner: File.open(Rails.root.join('app/assets/images/noimage/large.png'))
      )
    end

    let(:banner) do
      create(
        :spree_featured_banner,
        taxon: taxon,
        image: File.open(Rails.root.join('app/assets/images/noimage/large.png'))
      )
    end

    context 'when taxon has inner_banner' do
      it 'returns the inner_banner of taxon' do
        expect(taxon_or_banner_image(taxon, banner)).to eql taxon.inner_banner
      end
    end

    context 'when taxon#inner_banner does not exist but banner#image does' do
      before { taxon.update(inner_banner: nil) }

      it 'return the banner image' do
        expect(taxon_or_banner_image(taxon, banner)).to eql banner.image
      end
    end

    context 'when neither taxon#inner_banner nor banner#image exist' do
      before do
        taxon.update(inner_banner: nil)
        banner.update(image: nil)
      end

      it 'return the banner image' do
        expect(taxon_or_banner_image(taxon, banner)).to include 'noimage'
      end
    end
  end

  describe '#banner_or_taxon_image' do
    let(:taxon) do
      create(
        :spree_taxon,
        inner_banner: File.open(Rails.root.join('app/assets/images/noimage/large.png'))
      )
    end

    let(:banner) do
      create(
        :spree_featured_banner,
        taxon: taxon,
        image: File.open(Rails.root.join('app/assets/images/noimage/large.png'))
      )
    end

    context 'when banner has image' do
      it 'returns the image of banner' do
        expect(banner_or_taxon_image(banner)).to eql banner.image(:large)
      end
    end

    context 'when banner#image does NOT exist but taxon#inner_banner does' do
      before { banner.update(image: nil) }

      it 'return the taxon inner_banner' do
        expect(banner_or_taxon_image(banner)).to eql taxon.inner_banner
      end
    end

    context 'when neither taxon#inner_banner nor  banner#image exist' do
      before do
        taxon.update(inner_banner: nil)
        banner.update(image: nil)
      end

      it 'return the banner image' do
        expect(banner_or_taxon_image(banner)).to include 'noimage'
      end
    end
  end
end
