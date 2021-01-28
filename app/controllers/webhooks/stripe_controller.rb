class Webhooks::StripeController < ActionController::Base
  protect_from_forgery with: :exception, except: :index

  def index
    event = verify_and_extract_event
    return if performed?

    event_sub_object = act_on_event(event)
    StripeService.save_stripe_event(event, event_sub_object)

    head :ok
  end

  private

  def act_on_event(event)
    action_map = map_stripe_event_type_to_handler
    send(action_map[event.type], event)
  end

  def map_stripe_event_type_to_handler
    {
      'invoice.created' => :invoice_created_handler,
      'invoice.updated' => :invoice_updated_handler,
      'invoice.payment_failed' => :invoice_updated_handler,
      'invoice.payment_succeeded' => :invoice_updated_handler,
      'invoice.subscription.updated' => :subscription_updated_handler
    }
  end

  def invoice_created_handler(event)
    StripeService.create_invoice_record(event)
  end

  def invoice_update_handler(event)
    StripeService.update_invoice_record(event)
  end

  def subscription_updated_handler(event)
    StripeService.update_subscription_from_webhook(event)
  end

  def verify_and_extract_event
    payload = request.body.read
    signature_header = request.env['HTTP_STRIPE_SIGNATURE']

    Stripe::Webhook.construct_event(
      payload, signature_header, ENV['STRIPE_WEBHOOKS_SIGNING_SECRET']
    )
  rescue JSON::ParserError, Stripe::SignatureVerificationError
    # Invalid payload or Invalid signature
    head :bad_request
  end
end
