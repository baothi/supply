RSpec.shared_examples 'a social links component' do
  describe 'Active Model callback' do
    it { is_expected.to callback(:format_fb_and_ig_urls).before(:save) }
    it { is_expected.to callback(:smart_add_url_protocol).before(:save) }
  end
end
