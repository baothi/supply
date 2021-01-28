module Spree::ProductsAndVariants::Compliantable
  extend ActiveSupport::Concern

  included do
    attr_accessor :compliance_issues

    after_initialize :init_compliance_issues

    # after_commit :refresh_compliance!
  end

  def init_compliance_issues
    @compliance_issues = {}
    @compliance_issues[:submission_errors] = []
    @compliance_issues[:marketplace_errors] = []
  end

  def add_marketplace_compliance_issue(issue)
    @compliance_issues[:marketplace_errors] << issue
  end

  def add_submission_compliance_issue(issue)
    @compliance_issues[:submission_errors] << issue
  end

  def clear_compliance_logs
    init_compliance_issues
  end

  def has_submission_compliance_errors?
    @compliance_issues[:submission_errors].count.positive? && no_variant_has_inventory
  end

  def no_variant_has_inventory
    # Hack to allow approval when some variants have inventory
    no_inventory_errors = @compliance_issues[:submission_errors].
                          join.scan(/(?=We require at least 1 to be in stock)/).count
    total_errors = @compliance_issues[:submission_errors].count

    return true unless self.count_on_hand.positive?

    total_errors != no_inventory_errors
  end

  def does_not_have_submission_compliance_errors?
    !has_submission_compliance_errors?
  end

  def friendly_submission_compliance_errors_message
    @compliance_issues[:submission_errors].join(',')
  end

  def submission_errors
    @compliance_issues[:submission_errors]
  end

  def has_marketplace_compliance_errors?
    @compliance_issues[:marketplace_errors].count.positive?
  end

  def does_not_have_marketplace_compliance_errors?
    !has_marketplace_compliance_errors?
  end

  def friendly_marketplace_compliance_errors_message
    @compliance_issues[:marketplace_errors].join(',')
  end

  def marketplace_errors
    @compliance_issues[:marketplace_errors]
  end

  def friendly_compliance_errors
    self.compliance_issues.values.join('. ')
  end

  def update_product_compliance_status!
    init_compliance_issues
    run_submission_compliance_check
    run_marketplace_compliance_check

    self.update_columns(
      submission_compliant: !has_submission_compliance_errors?,
      submission_compliance_log: self.friendly_submission_compliance_errors_message,
      submission_compliance_status_updated_at: DateTime.now,
      marketplace_compliant: !has_marketplace_compliance_errors?,
      marketplace_compliance_log: self.friendly_marketplace_compliance_errors_message,
      marketplace_compliance_status_updated_at: DateTime.now
    )

    self.reload
  end

  def refresh_compliance!
    Shopify::UpdateComplianceWorker.perform_async(self.class.name, self.id)
  end

  def refresh_compliance_now!
    Shopify::UpdateComplianceWorker.new.perform(self.class.name, self.id)
  end
end
