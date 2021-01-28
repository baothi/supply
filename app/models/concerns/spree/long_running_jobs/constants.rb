module Spree::LongRunningJobs::Constants
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
    validates_presence_of :action_type
    validates_presence_of :job_type
    validates_presence_of :status
    validates_presence_of :initiated_by

    action_types = %w(import export generation)
    jobs_types =
      %w(products_export products_import images_import options_import options_export
         generate_credentials approval other_export webhooks_create shopify_import orders_import
         orders_export order_issue_reports_export images_export image_counter products_categorize
         events_import events_export
         order_risks_import cache_update fulfillments_import
         csv_export variant_costs_export order_generation email_notification delete_customers
         woocommerce)

    initiated_by = %w(user system)

    Dropshipper::ConstantsHelper.create_constant_from_collection(
      'Spree::LongRunningJob', 'ACTION_TYPES', action_types
    )

    Dropshipper::ConstantsHelper.create_constant_from_collection(
      'Spree::LongRunningJob', 'JOB_TYPES', jobs_types
    )

    Dropshipper::ConstantsHelper.create_constant_from_collection(
      'Spree::LongRunningJob', 'INITIATED_BY', initiated_by
    )

    validates :action_type, inclusion: { in: self.const_get('ACTION_TYPES') }
    validates :job_type, inclusion: { in: self.const_get('JOB_TYPES') }
    validates :initiated_by, inclusion: { in: self.const_get('INITIATED_BY') }

    # Serializers
    serialize :hash_option_1, Hash
    serialize :hash_option_2, Hash
    serialize :hash_option_3, Hash
    serialize :array_option_1, Array
    serialize :array_option_2, Array
    serialize :array_option_3, Array
  end
end
