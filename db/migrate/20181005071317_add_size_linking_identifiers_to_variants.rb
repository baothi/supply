class AddSizeLinkingIdentifiersToVariants < ActiveRecord::Migration[6.0]
  def change
    # For Auto Matching / Linking to objects
    add_column :spree_variants, :supplier_size_option_id, :integer
    add_column :spree_variants, :platform_size_option_id, :integer

    # For Interlinking
    add_column :spree_supplier_size_options,
               :platform_size_option_id, :integer
  end
end
