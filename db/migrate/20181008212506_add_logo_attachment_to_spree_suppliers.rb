class AddLogoAttachmentToSpreeSuppliers < ActiveRecord::Migration[6.0]
  def up
    add_attachment :spree_suppliers, :logo
  end

  def down
    remove_attachment :spree_suppliers, :logo
  end
end
