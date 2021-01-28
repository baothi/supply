namespace :webhooks do
  desc 'Re-create retailers webhooks'
  task recreate_retailer_webhooks: :environment do
    Spree::Retailer.find_each do |retailer|
      credential = retailer.shopify_credential
      set_up_webhook_creation_job(credential) unless credential.nil?
      puts "Initiated job to update retailer webhooks for #{retailer.name}"
    end

    puts 'All done'
  end

  def set_up_webhook_creation_job(credential)
    job = Spree::LongRunningJob.create(
      action_type: 'import',
      job_type: 'shopify_import',
      initiated_by: 'user',
      retailer_id: credential.teamable.id,
      teamable_type: credential.teamable.class.to_s,
      teamable_id: credential.teamable.id
    )

    Shopify::WebhookCreationJob.perform_later(job.internal_identifier)
  end
end
