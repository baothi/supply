class StripeService
  def self.make_charge(stripe_token, object)
    charge = Stripe::Charge.create(
      amount: (object.application_fee * 100).round,
      currency: 'usd',
      description: object.retailer.registration_fee_description,
      source: stripe_token,
      receipt_email: object.email,
      metadata: {
        supplier_name: object.supplier_name,
        applicant_name: object.full_name,
        supplier_email: object.email
      }
    )
    return charge[:id] if charge[:paid] && charge[:captured]
  rescue Stripe::StripeError => e
    puts e
    nil
  end

  def self.charge_stripe_customer(customer, amt, description, card, order_id = '')
    if amt < 0.50
      return OpenStruct.new(captured: true, paid: true, amount: 0, id: "payment-waived-#{order_id}")
    end

    charge = Stripe::Charge.create(
      amount: (amt * 100).round,
      currency: 'usd',
      description: description,
      customer: customer.customer_identifier,
      source: card
    )
    charge
  rescue Stripe::StripeError => e
    OpenStruct.new(error: e.message, captured: false)
  end

  def self.create_stripe_customer(strippable)
    customer = Stripe::Customer.create(
      description: "Customer object for #{strippable.name} (#{strippable.class.name})",
      email: strippable.email,
      metadata: { 'Customer Type': strippable.class.name, 'Customer ID': strippable.id }
    )

    save_customer_to_db(StripeCustomer.new(strippable: strippable), customer)
  rescue Stripe::StripeError => e
    puts e
    nil
  end

  def self.save_customer_to_db(customer_model, customer)
    customer_model.update(
      strippable: customer_model.strippable,
      customer_identifier: customer.id,
      account_balance: customer.account_balance,
      currency: customer.currency,
      default_source: customer.default_source,
      delinquent: customer.delinquent,
      description: customer.description,
      email: customer.email,
      discount: customer.discount
    )

    customer_model
  end

  def self.add_card_to_customer(stripe_customer, card_token)
    customer = Stripe::Customer.retrieve(stripe_customer.customer_identifier)
    card = customer.sources.create(source: card_token)
    return nil unless card

    # TODO: Why is this being called twice?
    customer = Stripe::Customer.retrieve(stripe_customer.customer_identifier)
    save_customer_to_db(stripe_customer, customer)
    update_stripe_cards_to_db(StripeCard.new(stripe_customer: stripe_customer), card)
  rescue Stripe::StripeError => e
    puts e
  end

  def self.update_stripe_cards_to_db(card_model, card)
    card_model.update(
      card_identifier: card.id,
      address_city: card.address_city,
      address_country: card.address_country,
      address_line1: card.address_line1,
      address_line1_check: card.address_line1_check,
      address_line2: card.address_line2,
      address_state: card.address_state,
      address_zip: card.address_zip,
      address_zip_check: card.address_zip_check,
      brand: card.brand,
      country: card.country,
      customer_identifier: card.customer,
      cvc_check: card.cvc_check,
      dynamic_last4: nil, # card.dynamic_last4, Not supported by the version of StripeMock
      exp_month: card.exp_month,
      exp_year: card.exp_year,
      fingerprint: card.fingerprint,
      funding: card.funding,
      last4: card.last4,
      name: card.name
    )

    card_model
  end

  def self.set_default_card(stripe_customer, stripe_card)
    customer = Stripe::Customer.retrieve(stripe_customer.customer_identifier)
    customer.default_source = stripe_card.card_identifier
    customer.save
    save_customer_to_db(stripe_customer, customer)
  rescue Stripe::StripeError => e
    puts e
  end

  def self.delete_card(stripe_customer, stripe_card)
    customer = Stripe::Customer.retrieve(stripe_customer.customer_identifier)
    card = customer.sources.retrieve(stripe_card.card_identifier).delete
    StripeCard.find_by(card_identifier: card.id).destroy

    customer = Stripe::Customer.retrieve(stripe_customer.customer_identifier)
    save_customer_to_db(stripe_customer, customer)
  rescue Stripe::StripeError => e
    puts e
  end

  def self.create_or_update_subscription(stripe_customer, plan)
    if stripe_customer.stripe_subscription.blank?
      return create_new_subscription(stripe_customer, plan)
    end

    update_subscription(stripe_customer, plan)
  end

  def self.create_new_subscription(stripe_customer, plan)
    subscription = Stripe::Subscription.create(
      customer: stripe_customer.customer_identifier,
      plan: plan.plan_identifier
    )

    return false unless subscription

    save_subscription_to_model(
      StripeSubscription.new(stripe_customer: stripe_customer), subscription, plan
    )
  rescue Stripe::StripeError => e
    puts e
    nil
  end

  def self.save_subscription_to_model(model, subscription, plan)
    model.update(
      subscription_identifier: subscription.id,
      plan_identifier: subscription.plan.id,
      customer_identifier: subscription.customer,
      stripe_plan_id: plan.id,
      cancel_at_period_end: subscription.cancel_at_period_end,
      canceled_at: time_from_timestamp_or_nil(subscription.canceled_at),
      current_period_start: time_from_timestamp_or_nil(subscription.current_period_start),
      current_period_end: time_from_timestamp_or_nil(subscription.current_period_end),
      quantity: subscription.quantity,
      start: time_from_timestamp_or_nil(subscription.start),
      ended_at: time_from_timestamp_or_nil(subscription.ended_at),
      trial_start: subscription.trial_start,
      trial_end: subscription.trial_end,
      status: subscription.status
    )

    model
  end

  def self.update_subscription(stripe_customer, plan)
    customer_sub = stripe_customer.stripe_subscription
    subscription = Stripe::Subscription.retrieve(customer_sub.subscription_identifier)
    subscription.plan = plan.plan_identifier
    return false unless subscription.save

    subscription = Stripe::Subscription.retrieve(customer_sub.subscription_identifier)
    save_subscription_to_model(customer_sub, subscription, plan)
  rescue Stripe::StripeError => e
    puts e
    nil
  end

  def self.create_invoice_record(event)
    event_invoice = event.data.object
    stripe_customer = StripeCustomer.find_by(customer_identifier: event_invoice.customer)
    save_invoice_to_db(StripeInvoice.new(stripe_customer: stripe_customer), event_invoice)
  end

  def self.save_invoice_to_db(record, event_invoice)
    record.update(
      invoice_identifier: event_invoice.id,
      amount_due: event_invoice.amount_due,
      application_fee: event_invoice.application_fee,
      attempt_count: event_invoice.attempt_count,
      attempted: event_invoice.attempted,
      charge_identifier: event_invoice.charge,
      closed: event_invoice.closed,
      currency: event_invoice.currency,
      customer_identifier: event_invoice.customer,
      date: time_from_timestamp_or_nil(event_invoice.date),
      description: event_invoice.description,
      discount: event_invoice.discount,
      forgiven: event_invoice.forgiven,
      next_payment_attempt: time_from_timestamp_or_nil(event_invoice.next_payment_attempt),
      paid: event_invoice.paid,
      period_end: time_from_timestamp_or_nil(event_invoice.period_end),
      period_start: time_from_timestamp_or_nil(event_invoice.period_start),
      receipt_number: event_invoice.receipt_number,
      starting_balance: event_invoice.starting_balance,
      statement_descriptor: event_invoice.statement_descriptor,
      subscription_identifier: event_invoice.subscription,
      subtotal: event_invoice.subtotal,
      total: event_invoice.total
    )

    record
  end

  def self.update_invoice_record(event)
    event_invoice = event.data.object
    invoice = StripeInvoice.find_by(invoice_identifier: event_invoice.id)
    return unless invoice

    save_invoice_to_db(invoice, event_invoice)
  end

  def self.update_subscription_from_webhook(event)
    sub_object = event.data.object
    subscription = StripeSubscription.find_by(subscription_identifier: sub_object.id)
    save_subscription_to_model(
      subscription, sub_object, subscription.stripe_customer, subscription.plan
    )
  end

  def self.time_from_timestamp_or_nil(timestamp)
    timestamp && Time.zone.at(timestamp)
  end

  def self.save_stripe_event(event, event_sub_object)
    StripeEvent.create(
      event_identifier: event.id,
      event_created: time_from_timestamp_or_nil(event.created),
      stripe_eventable: event_sub_object,
      event_object: event
    )
  end

  # TODO: Make this rerunnable.
  def self.refund_charge(stripe_charge_id:, amount: 0.0, payment_id:, refund_reason_id:)
    response = { error: nil, success: nil, refund_id: nil }
    begin
      refund = Stripe::Refund.create(
        charge: stripe_charge_id,
        amount: (amount * 100).to_i
      )
      spree_refund = Spree::Refund.create!(
        payment_id: payment_id, refund_reason_id: refund_reason_id,
        amount: amount, transaction_id: refund[:id]
      )
      Spree::Payment.find(payment_id).refund!
      response[:success] = 'Refund successfully'
      response[:refund_id] = spree_refund.id
    rescue Stripe::InvalidRequestError => e
      puts e.message
      response[:error] = e.message
    end

    response
  end

  def self.refund_partial_charge(stripe_charge_id:, amount: 0.0, payment_id:, refund_reason_id:)
    response = { error: nil, success: nil, refund_id: nil }
    begin
      refund = Stripe::Refund.create(
        charge: stripe_charge_id,
        amount: (amount * 100).to_i
      )
      spree_refund = Spree::Refund.create!(
        payment_id: payment_id, refund_reason_id: refund_reason_id,
        amount: amount, transaction_id: refund[:id]
      )
      Spree::Payment.find(payment_id).partially_refund!
      response[:success] = 'Refund successfully'
      response[:refund_id] = spree_refund.id
    rescue Stripe::InvalidRequestError => e
      puts e.message
      response[:error] = e.message
    end

    response
  end
end
