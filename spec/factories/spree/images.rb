FactoryBot.define do
  factory :spree_image, class: 'Spree::Image' do
    attachment { File.new(Spree::Core::Engine.root + 'spec/fixtures' + 'thinking-cat.jpg') }
  end
end
