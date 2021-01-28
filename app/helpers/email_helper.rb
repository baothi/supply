module EmailHelper
  def email_image_tag(image, **options)
    attachments.inline[image] = {
      content: File.read(Rails.root.join("app/assets/images/#{image}")),
      mime_type: 'image/png'
    }

    image_tag attachments[image].url, **options
  end
end
