class CreateSpreeCouriers < ActiveRecord::Migration[6.0]
  def change
    create_table :spree_couriers do |t|
      t.string :code, null: false, index: true # e.g FEDEX, USPS, UPS, DHL
      t.string :name, null: false, index: true # FedEx, USPS, UPC, DHL
      t.string :website # Website e.g. http://www.dhl.com
      t.boolean :active
      # TODO: Consider adding valid countries that Courier Serves in
      t.timestamps
    end
  end
end
