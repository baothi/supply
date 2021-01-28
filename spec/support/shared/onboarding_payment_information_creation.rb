RSpec.shared_examples 'a payment information creation' do |kind|
  it 'creates Payment Information' do
    payment = create :spree_supplier_onboarding, kind
    expect(payment.send("create_#{kind}")).to be_a Spree::PaymentInformation
  end
end
