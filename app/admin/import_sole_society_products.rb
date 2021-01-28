ActiveAdmin.register_page 'Import Sole Society Products' do
  menu label: 'Import Sole Society Products', parent: 'File Process'
  content do
    render partial: 'admin/products/import_sole_society'
  end
end
