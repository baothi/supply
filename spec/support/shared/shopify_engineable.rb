RSpec.shared_examples 'capable of interacting with shopify' do
  let (:clean_klass_name) do
    shopify_klass.to_s.split('::')[1]
  end

  describe '.kalling_klass' do
    it 'expects to return the correct value' do
      expect(described_class.kalling_klass).to eq clean_klass_name
    end
  end

  describe '.shopify_klass' do
    it 'expects to return the correct value' do
      expect(described_class.shopify_klass).to eq shopify_klass
    end
  end

  describe '.create' do
    it 'calls the proper shopify base class' do
      allow(shopify_klass).to receive(:new).and_return(true)
      expect(shopify_klass).to receive(:new)
      described_class.create({})
    end
  end

  describe '.find' do
    it 'calls the proper shopify base class' do
      allow(shopify_klass).to receive(:find).and_return(true)
      expect(shopify_klass).to receive(:find)
      described_class.find(:all, {})
    end
  end

  describe '.count' do
    it 'calls the proper shopify base class' do
      allow(shopify_klass).to receive(:count).and_return(3)
      expect(shopify_klass).to receive(:count)
      described_class.count
    end
  end
end
