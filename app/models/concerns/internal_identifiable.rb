module InternalIdentifiable
  extend ActiveSupport::Concern

  included do
    before_validation :generate_internal_identifier, on: :create
    scope :missing_internal_identifier,
          -> { where("internal_identifier is null or internal_identifier = ''") }
    scope :has_internal_identifier,
          -> { where("internal_identifier <> ''") }
  end

  def generate_internal_identifier
    return unless self.internal_identifier.blank?

    begin
      self.internal_identifier = SecureRandom.hex(20)
    end while self.class.exists?(internal_identifier: internal_identifier)
  end

  class_methods do
    def generate_internal_identifiers!
      # We should only want this to run this once
      self.missing_internal_identifier.find_each do |c|
        c.generate_internal_identifier
        c.save
      end
    end
  end
end
