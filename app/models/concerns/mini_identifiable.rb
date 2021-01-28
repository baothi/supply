module MiniIdentifiable
  # This is the cousin of InternalIdentifier. Generates values up to 5 charactesrs
  # Up to 11,881,376 unique values.
  extend ActiveSupport::Concern

  included do
    before_validation :generate_mini_identifier, on: :create
    scope :missing_mini_identifier,
          -> { where("mini_identifier is null or mini_identifier = ''") }
    scope :has_mini_identifier,
          -> { where("mini_identifier <> ''") }
  end

  def generate_mini_identifier
    return unless self.mini_identifier.blank?

    begin
      self.mini_identifier = SecureRandom.hex(3)
    end while self.class.exists?(mini_identifier: mini_identifier)
  end

  class_methods do
    def generate_mini_identifiers!
      self.missing_mini_identifier.find_each do |c|
        c.generate_mini_identifier
        c.save
      end
    end
  end
end
