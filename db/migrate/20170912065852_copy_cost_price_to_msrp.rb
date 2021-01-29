class CopyCostPriceToMsrp < ActiveRecord::Migration[6.0]
  def up
    Spree::Variant.all.each do |variant|
      variant.msrp_price = variant.cost_price
      variant.msrp_currency = variant.cost_currency
      variant.save
    end
  end

  def down
  end
end
