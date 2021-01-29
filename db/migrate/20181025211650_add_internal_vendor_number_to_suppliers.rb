class AddInternalVendorNumberToSuppliers < ActiveRecord::Migration[6.0]
  def change
    # Set as a string on purpose
    add_column :spree_suppliers, :internal_vendor_number, :string
    add_column :spree_suppliers, :edi_identifier, :string
    # Other Useful EDI information. Will move to another model in future
    add_column :spree_suppliers, :edi_van_name, :string
    add_column :spree_suppliers, :edi_contact_full_name, :string
    add_column :spree_suppliers, :edi_contact_email, :string
    add_column :spree_suppliers, :edi_contact_phone_number, :string
  end
end
