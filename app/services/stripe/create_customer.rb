class Stripe::CreateCustomer
  include Stripe::Callbacks

  after_customer_updated! do |customer, _event|
    puts "Customer Created!: #{customer.inspect}".yellow
  end
end
