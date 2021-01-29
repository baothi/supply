class CopyShopifyAddresses < ActiveRecord::Migration[6.0]
  def up
    begin
      Spree::Retailer.find_each do |retailer|
        unless retailer.legal_entity_address.present?
          address = Spree::Address.new
          attrs = %i(address1 address2 address2 city zipcode phone)
          attrs.each do |attr|
            address[attr] = retailer[attr].blank? ? 'N/A' : retailer[attr]
          end
          address.name_of_state = retailer.state

          if retailer.shop_owner.present?
            address.transfer_from_shop_owner(retailer.shop_owner)
          else
            address.set_unknown_names
          end

          retailer.legal_entity_address=address
          retailer.save!
          # ActiveRecord::Base.transaction do
          #   address.save
          #   retailer.save
          # end
        end

        unless retailer.shipping_address.present?
          address = Spree::Address.new
          attrs = %i(address1 address2 address2 city zipcode phone)
          attrs.each do |attr|
            address[attr] = retailer[attr].blank? ? 'N/A' : retailer[attr]
          end
          address.name_of_state = retailer.state

          if retailer.shop_owner.present?
            address.transfer_from_shop_owner(retailer.shop_owner)
          else
            address.set_unknown_names
          end

          retailer.shipping_address=address
          retailer.save!
          # ActiveRecord::Base.transaction do
          #   address.save
          #   retailer.save
          # end
        end
      end
    rescue => ex
      puts "CopyShopifyAddresses: #{ex}".red
    end
  end

  def down
  end
end
