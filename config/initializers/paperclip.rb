if Rails.env.test?
  # Paperclip::Attachment.default_options[:url] = ENV['SITE_URL']
  Paperclip::Attachment.default_options[:url] =
    "#{Rails.root}/spec_uploads/:class/:attachment/:id_partition/:style/:filename"
  Paperclip::Attachment.default_options[:path] =
    "#{Rails.root}/spec_uploads/:class/:attachment/:id_partition/:style/:filename"
end
Paperclip.options[:content_type_mappings] = {
  csv: %w(text/plain application/vnd.ms-excel application/octet-stream)
}
# Paperclip::Attachment.default_options[:s3_host_name] = 's3-us-west-2.amazonaws.com'
