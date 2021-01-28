ActiveAdmin.register Spree::PlatformSizeOption do
  config.filters = false

  actions :all, except: [:destroy]

  menu label: 'Sizes', parent: 'Platform Options'
end
