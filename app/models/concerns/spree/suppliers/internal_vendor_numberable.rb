module Spree::Suppliers::InternalVendorNumberable
  extend ActiveSupport::Concern

  included do
    before_validation :generate_internal_vendor_number, on: :create
    scope :missing_internal_vendor_number,
          -> { where("internal_vendor_number is null or internal_vendor_number = ''") }
    scope :has_internal_vendor_number,
          -> { where("internal_vendor_number <> ''") }
  end

  def generate_internal_vendor_number
    return unless self.internal_vendor_number.blank?

    begin
      self.internal_vendor_number = 5.times.map { rand(1..9) }.join
    end while self.class.exists?(internal_vendor_number: internal_vendor_number)
  end

  class_methods do
    def generate_internal_vendor_numbers!
      # We should only want this to run this once
      self.missing_internal_vendor_number.find_each do |s|
        s.generate_internal_vendor_number
        s.save
      end
    end
  end
end
