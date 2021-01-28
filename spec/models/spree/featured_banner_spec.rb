require 'rails_helper'

RSpec.describe Spree::FeaturedBanner, type: :model do
  subject { build(:spree_featured_banner) }

  it_behaves_like 'an internal_identifiable model'

  describe 'Model from Factory' do
    it { is_expected.to be_valid }

    context 'when any of the required fields is nil' do
      it { expect(build(:spree_featured_banner, title: nil)).not_to be_valid }
    end
  end

  describe 'Validators' do
    it { is_expected.to validate_presence_of(:title) }
  end

  describe 'Active model associations' do
    it { is_expected.to belong_to(:taxon) }
  end

  describe 'Paperclip attachment' do
    it { is_expected.to have_attached_file(:image) }
    it { is_expected.to validate_attachment_content_type(:image).allowing('image/jpeg') }
  end
end
