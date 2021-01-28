class AlgoliaIndexJob
  include Sidekiq::Worker

  def perform(id, remove)
    if remove
      index = Algolia::Index.new(Spree::Product.index_name)
      index.delete_object(id)
    else
      product = Spree::Product.find(id)
      return unless product.approved?

      product.index!
    end
  end
end
