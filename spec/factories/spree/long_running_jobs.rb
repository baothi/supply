FactoryBot.define do
  factory :spree_long_running_job, class: 'Spree::LongRunningJob' do
    user factory: :spree_user
    retailer factory: :spree_retailer
    supplier factory: :spree_supplier
    job_type { Spree::LongRunningJob::JOB_TYPES.sample }
    action_type { Spree::LongRunningJob::ACTION_TYPES.sample }
    initiated_by { Spree::LongRunningJob::INITIATED_BY.sample }
  end
end
