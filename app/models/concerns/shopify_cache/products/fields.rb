module ShopifyCache::Products::Fields
  extend ActiveSupport::Concern

  included do
    field :vendor, type: String
    field :product_type, type: String
    field :created_at, type: String
    field :body_html, type: String
    field :handle, type: String
    field :title, type: String
    field :updated_at, type: String
    field :published_at, type: String
    field :tags, type: String
    field :admin_graphql_api_id, type: String
    field :published_scope, type: String
    # Hingeto fields
    field :role, type: String
    field :shopify_url, type: String
    # We use string to keep with Shopify convention for date
    field :deleted_at, type: String

    field :last_generated_variants_at, type: String

    validates_presence_of :shopify_url
    validates_presence_of :role
    validates_presence_of :variants
  end
end
