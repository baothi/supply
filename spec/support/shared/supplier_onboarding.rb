RSpec.shared_examples 'onboarding_error_page' do |route|
  before do
    @steps = %w(basic_information payment_information contact_information completed)
    supplier_onboarding.update(current_step: @steps.sample)
  end

  it 'redirects to error page' do
    visit route
    expect(page.current_path).to eq '/supplier_onboarding/error'
  end
end
