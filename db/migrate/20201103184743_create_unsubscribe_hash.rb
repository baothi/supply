class CreateUnsubscribeHash < ActiveRecord::Migration[6.0]
  def change
    Spree::Retailer.find_each do |retailer|
      retailer.update(unsubscribe_hash: SecureRandom.hex)
    end
  end
end
