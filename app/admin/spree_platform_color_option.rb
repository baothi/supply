ActiveAdmin.register Spree::PlatformColorOption do
  config.filters = false

  actions :all, except: [:destroy]

  menu label: 'Colors', parent: 'Platform Options'
end
