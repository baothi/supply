### This seed file is for setting up Platform Sizes
sizes = []

(0..50).step(0.5).each do |i|
  sizes << i.to_s
end

additional_options = %w(2XS XS S M L XL 2XL 3XL 4XL 5XL 6XL 7XL OSFA OSFM NONE)
sizes = sizes + additional_options

# For now, we do not deal with 'double options' e.g. 32 30
# Single Dimensional Options
sizes.each_with_index do |size_name, index|
  # Create Platform Size Option
  Spree::PlatformSizeOption.find_or_create_by!(name_1: size_name, name_2: nil) do |platform_size|
    platform_size.presentation = size_name
    platform_size.position = index * 5
  end
end
