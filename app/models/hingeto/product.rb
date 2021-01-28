# The purpose of this model is to serve as a global index
# of all approved Hingeto Products
class Hingeto::Product
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Search

  field :internal_identifier, type: String # II from Main Application
  field :_id, type: String, default: -> { internal_identifier }

  # Name of the application as this Index may also contain MXED product
  field :app, type: String, default: 'supply'

  # Product Name
  field :name, type: String
  field :description, type: String
  field :image_urls, type: Array

  # Identifiers
  field :supplier_shopify_identifier, type: String
  field :supplier_internal_identifier, type: String

  # Availability
  field :discontinue_on, type: String
  field :deleted_at, type: String
  field :quantity, type: String # This is adjusted for buffer
  field :original_quantity, type: Integer # Original quantity without Supplier buffer

  has_many :variants, class_name: 'Hingeto::Variant', foreign_key: :product_internal_identifier
end
