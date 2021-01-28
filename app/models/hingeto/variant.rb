# The purpose of this model is to serve as a global index
# of all approved Hingeto Variants
class Hingeto::Variant
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Search

  field :internal_identifier, type: String # II from Main Application
  field :_id, type: String, default: -> { internal_identifier }

  # Name of the application as this Index may also contain MXED product
  field :app, type: String, default: 'supply'
  field :product_internal_identifier, type: String # Foreign Key

  # Product Name
  field :image_urls, type: Array

  # Identifiers
  field :supplier_shopify_identifier, type: String
  # We keep track of all identifiers it ever has had
  field :supplier_shopify_identifiers, type: Array

  field :supplier_internal_identifier, type: String

  # Availability
  field :discontinue_on, type: String
  field :deleted_at, type: String
  field :quantity, type: String # This is adjusted for buffer
  field :original_quantity, type: Integer # Original quantity without Supplier buffer

  belongs_to :product, class_name: 'Hingeto::Product'
end
