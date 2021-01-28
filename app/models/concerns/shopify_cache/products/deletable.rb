module ShopifyCache::Products::Deletable
  extend ActiveSupport::Concern

  included do
    # Exclude deleted products
    default_scope -> { where(deleted_at: nil) }
  end

  class_methods do
    def mark_as_deleted!(supplier:, shopify_identifier:)
      raise 'Supplier is required' if supplier.nil?
      raise 'Identifier is required' if shopify_identifier.nil?

      p = where(id: shopify_identifier).first
      return if p.nil?

      p.mark_as_deleted!
    end
  end

  def mark_as_deleted!
    self[:deleted_at] = DateTime.now
    self.save!
  end

  def mark_as_undeleted!
    self[:deleted_at] = nil
    self.save!
  end
end
