# Retailer
retailer_platform_features = [
    {
        plan_name: 'retailer-core',
        stripe_plan_identifier: 'retailer-core',
        active: true
    },
    {
        plan_name: 'retailer-premium',
        stripe_plan_identifier: 'retailer-premium',
        active: true
    },
    {
        plan_name: 'retailer-premium-mxed',
        stripe_plan_identifier: 'retailer-premium-mxed',
        active: true
    },
    {
        plan_name: 'retailer-core-99-special',
        stripe_plan_identifier: 'retailer-core-99-special',
        active: true
    },
    {
        plan_name: 'retailer-core-49-special',
        stripe_plan_identifier: 'retailer-core-49-special',
        active: true
    }
]

retailer_platform_features.each do |retailer_platform_feature|
  Spree::RetailerPlatformFeature.find_or_create_by!(
    plan_name: retailer_platform_feature[:plan_name]
  ) do |feature|
    feature.stripe_plan_identifier = retailer_platform_feature[:stripe_plan_identifier]
    feature.active = retailer_platform_feature[:active]
  end
end
