class CreateSpreeWooCredentials < ActiveRecord::Migration[6.0]
  def change
    create_table :spree_woo_credentials do |t|
      t.string :store_url
      t.string :consumer_key
      t.string :consumer_secret
      t.string :version
      t.string :teamable_type
      t.integer :wooteamable_id
      t.datetime :uninstalled_at

      t.timestamps
    end
  end
end
