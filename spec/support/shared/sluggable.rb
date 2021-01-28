RSpec.shared_examples 'a sluggable model' do  |factory|
  # This is typically powered by friendly_id

  it 'generates a slug before saving' do
    subject.slug = nil
    subject.save!
    expect(subject.slug).not_to be_nil
  end

  it 'generates a unique slug' do
    name = 'Same Name for Supplier'
    object1 = FactoryBot.create(factory, name: name, slug: nil)
    object2 = FactoryBot.create(factory, name: name, slug: nil)
    expect(object1.slug).not_to eq object2.slug
  end
end
