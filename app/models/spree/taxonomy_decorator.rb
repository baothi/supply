Spree::Taxonomy.class_eval do
  scope :featureable, -> {
    where(name: ['License', 'Category', 'CustomFeatured'])
  }

  def featureable_taxons
    taxons.where.not(parent_id: nil)
  end

  def self.default_scope
    where(deleted_at: nil)
  end
end
