class CreateFeaturedBanners < ActiveRecord::Migration[6.0]
  def change
    create_table :spree_featured_banners do |t|
      t.string :internal_identifier, index: true
      t.string :title
      t.text :description
      t.references :taxon, foreign_key: { to_table: 'spree_taxons' }
      t.attachment :image

      t.timestamps
    end
  end
end
