### This seed file is for setting up Platform Colors
colors = 'Red, Orange, Yellow, Green, Blue, Black, Multi, Transparent, Pink, '\
         'White, Purple, Gray, No Color, Brown, Beige/Khaki'

colors = colors.split(',')
colors.each_with_index do |color_name, index|
  # Create Platform Color Option
  Spree::PlatformColorOption.find_or_create_by!(name: color_name) do |platform_color|
    platform_color.presentation = color_name
    platform_color.position = index * 5
  end
end
