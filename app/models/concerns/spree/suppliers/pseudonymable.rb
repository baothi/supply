# Used for generating pseudonyms to hide the true identity of suppliers
module Spree::Suppliers::Pseudonymable
  extend ActiveSupport::Concern

  included do
    before_validation :generate_pseudonym, on: :create
    scope :missing_pseudonym,
          -> { where("pseudonym is null or pseudonym = ''") }
    scope :has_pseudonym,
          -> { where("pseudonym <> ''") }
  end

  def generate_pseudonym
    return unless self.pseudonym.blank?

    begin
      self.pseudonym = Faker::IDNumber.invalid
    end while self.class.exists?(pseudonym: pseudonym)
  end

  class_methods do
    def generate_pseudonyms!
      # We should only want this to run this once
      self.missing_pseudonym.find_each do |c|
        c.generate_pseudonym
        c.save
      end
    end
  end
end
