# The purpose of this model is to serve as a global index
# of all Product in Retailer/Supplier stores
class ShopifyCache::Event
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  # Shopify fields
  field :subject_id, type: Integer
  field :created_at, type: String
  field :subject_type, type: String
  field :verb, type: String

  # Hingeto fields
  field :shopify_url, type: String
  field :role, type: String
  field :processed_at, type: String

  # Indices
  index({ subject_id: 1, subject_type: 1, role: 1, shopify_url: 1 }, background: true)
  index({ shopify_url: 1, processed_at: 1 }, background: true)

  validates_presence_of :shopify_url
  validates_presence_of :role

  scope :unprocessed, -> { where(processed_at: nil) }
  scope :processed, -> { where(:processed_at.nin => ['', nil]) }

  def mark_as_processed!
    self[:processed_at] = DateTime.now
    self.save!
  end

  def mark_as_unprocessed!
    self[:processed_at] = nil
    self.save!
  end
end
