class AddMsrpToVariants < ActiveRecord::Migration[6.0]
  def change
    add_column :spree_variants, :msrp_price, :decimal, precision: 8, scale: 2
    add_column :spree_variants, :msrp_currency, :string, default: 'USD'
  end
end
