module Spree
  module CommonBusiness
    extend ActiveSupport::Concern

    def can_use_platform_freely?
      access_granted? && has_subscription? && completed_onboarding?
    end

    def redirect_to_platform_onboarding?
      !completed_onboarding?
    end

    def access_granted?
      access_granted_at.present?
    end

    def grant_access!
      update_column(:access_granted_at, DateTime.now)
    end

    def revoke_access!
      update_column(:access_granted_at, nil)
    end

    def completed_onboarding?
      completed_onboarding_at.present?
    end

    def onboarded?
      completed_onboarding?
    end

    def complete_onboarding!
      update_column(:completed_onboarding_at, DateTime.now)
    end

    def remove_onboarding!
      update_column(:completed_onboarding_at, nil)
    end

    # Stripe Subscription Related

    def has_stripe_subscription?
      current_stripe_subscription_identifier.present?
    end

    def has_shopify_subscription?
      return false if current_shopify_subscription_identifier.blank?
      return false if self.shopify_credential.nil? || self.shopify_credential.uninstalled_at.present?
      return false unless platform == 'shopify'

      begin
        self.init
  
        recurring_charge = ShopifyAPI::RecurringApplicationCharge.find(current_shopify_subscription_identifier.to_i)
  
        return recurring_charge.nil? || (recurring_charge.status != 'accepted' || recurring_charge.status != 'active')
      rescue => exception
        self.shopify_credential.update(uninstalled_at: Time.now)
        update_trial_time! if self.class.to_s == "Spree::Retailer"
        return false
      end
    end

    def has_subscription?
      has_stripe_subscription? || has_shopify_subscription?
    end

    def stripe_dashboard_url
      return 'https://dashboard.stripe.com/test/' if Dropshipper.env.test?

      'https://dashboard.stripe.com/'
    end

    def stripe_dashboard_for_customer_link
      "#{stripe_dashboard_url}customers/#{current_stripe_customer_identifier}"
    end

    def stripe_dashboard_for_subscription_link
      "#{stripe_dashboard_url}subscriptions/#{current_stripe_subscription_identifier}"
    end

    def has_shopify_app_installed?
      shopify_credential.present?
    end
  end
end
