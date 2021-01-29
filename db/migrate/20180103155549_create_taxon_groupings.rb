class CreateTaxonGroupings < ActiveRecord::Migration[6.0]
  def change
    create_table :spree_taxon_groupings do |t|
      t.references :taxon, foreign_key: { to_table: 'spree_taxons' }
      t.references :grouping, foreign_key: { to_table: 'spree_groupings' }

      t.timestamps
    end
  end
end
