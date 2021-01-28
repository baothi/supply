Spree::Image.class_eval do
  delegate :url, to: :attachment, prefix: true, allow_nil: true

  belongs_to :previous_backup, class_name: 'Spree::Image', foreign_key: 'previous_image_id'

  after_destroy do |record|
    record.previous_backup.destroy if record.previous_backup
  end

  def large_url
    self&.attachment&.url(:large, false)
  end

  def upload_2_cloudinary!
    backup if previous_backup.nil?
    response = if Rails.env.development?
                 Cloudinary::Uploader.upload base64, smart_crop_options
               else
                 Cloudinary::Uploader.upload large_url, smart_crop_options
               end
    self.attachment = open(response['url'], ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)
    self.save
  end

  def smart_crop_options
    { crop: 'crop', gravity: 'face', effect: 'trim',
      border: { width: '20', color: 'white' } }
  end

  def original_photo_url
    return if attachment.nil?

    attachment.url(:original)
  end

  private

  def base64
    img_type = File.extname(large_url)
    img_url = URI.join(ActionController::Base.asset_host, large_url)
    img_data = Base64.encode64(open(img_url).read).delete("\n")
    "data:image/#{img_type};base64,#{img_data}"
  end

  def backup
    backup_image = Spree::Image.new
    backup_image.previous_image_id = id
    backup_image.viewable_type = viewable_type
    backup_image.viewable_id = viewable_id
    backup_image.attachment = attachment
    backup_image.created_at = created_at
    backup_image.save
  end
end
