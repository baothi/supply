class AddComplianceInformationToProductAndVariants < ActiveRecord::Migration[6.0]
  def change
    # These columns are used to cache the values of compliance of products
    # to minimize expensive calculations

    # Valid values include: true/false
    add_column :spree_products, :submission_compliant, :boolean
    add_column :spree_products, :submission_compliance_log, :text
    add_column :spree_products, :submission_compliance_status_updated_at, :datetime

    add_column :spree_products, :marketplace_compliant, :boolean
    add_column :spree_products, :marketplace_compliance_log, :text
    add_column :spree_products, :marketplace_compliance_status_updated_at, :datetime

    # Variants

    add_column :spree_variants, :submission_compliant, :boolean
    add_column :spree_variants, :submission_compliance_log, :text
    add_column :spree_variants, :submission_compliance_status_updated_at, :datetime

    add_column :spree_variants, :marketplace_compliant, :boolean
    add_column :spree_variants, :marketplace_compliance_log, :text
    add_column :spree_variants, :marketplace_compliance_status_updated_at, :datetime


  end
end
