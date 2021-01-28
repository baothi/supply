module Spree::Orders::PurchaseOrderNumberable
  extend ActiveSupport::Concern

  included do
    before_validation :generate_purchase_order_number, on: :create
    scope :missing_purchase_order_number,
          -> { where("purchase_order_number is null or purchase_order_number = ''") }
    scope :has_purchase_order_number,
          -> { where("purchase_order_number <> ''") }

    before_save :update_line_item_purchase_order_numbers,
                if: :purchase_order_number_changed?
  end

  def update_line_item_purchase_order_numbers
    self.line_items.update_all(purchase_order_number: self.purchase_order_number)
  end

  def generate_purchase_order_number
    return unless self.purchase_order_number.blank?

    begin
      # Expect Format of PO number - HS00006569987
      po_number = "#{7.times.map { rand(1..9) }.join}".rjust(11, '0')
      po_number = "HS#{po_number}"
      self.purchase_order_number = po_number
    end while self.class.exists?(purchase_order_number: purchase_order_number)
  end

  class_methods do
    def generate_purchase_order_numbers!
      # We should only want this to run this once
      self.missing_purchase_order_number.find_each do |s|
        s.generate_purchase_order_number
        s.save
      end
    end
  end
end
