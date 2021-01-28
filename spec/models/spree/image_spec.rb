require 'rails_helper'

RSpec.describe Spree::Image, type: :model do
  it 'responds to attachment_url' do
    expect(described_class.new).to respond_to(:attachment_url)
  end

  it 'resonds to original_photo_url' do
    expect(described_class.new).to respond_to(:original_photo_url)
  end
end
