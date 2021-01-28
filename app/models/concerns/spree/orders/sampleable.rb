module Spree::Orders::Sampleable
  # This is the cousin of InternalIdentifier. Generates values up to 5 charactesrs
  # Up to 11,881,376 unique values.
  extend ActiveSupport::Concern

  included do
    before_validation :generate_sample_order_number, on: :create
  end

  def generate_sample_order_number
    return unless self.source == 'app'
    return if self.number.include? 'SAMPLE'

    begin
      self.number = "SAMPLE-#{SecureRandom.hex(3).upcase}"
    end while self.class.exists?(number: number)
  end
end
