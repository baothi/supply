require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# module Supply
#   class Application < Rails::Application
#     # Initialize configuration defaults for originally generated Rails version.
#     config.load_defaults 6.0

#     # Settings in config/environments/* take precedence over those specified here.
#     # Application configuration can go into files in config/initializers
#     # -- all .rb files in that directory are automatically loaded after loading
#     # the framework and any gems in your application.
#   end
# end
module Dropshipper
  class Application < Rails::Application
    config.load_defaults 6.0
    config.to_prepare do
      # Load application's model / class decorators
      Dir.glob(File.join(File.dirname(__FILE__), '../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end

      # Load application's view overrides
      Dir.glob(File.join(File.dirname(__FILE__), '../app/overrides/*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        resource '*', headers: :any, methods: %i(get post options)
      end
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.active_job.queue_adapter = :sidekiq

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.autoload_paths << "#{Rails.root}/app/pdfs"
    config.autoload_paths << "#{Rails.root}/app/services"
    config.autoload_paths << "#{Rails.root}/app/serializers"
    config.autoload_paths << Rails.root.join('lib')
    config.autoload_paths << "#{Rails.root}/app/jobs/concerns"
    config.autoload_paths << "#{Rails.root}/app/workers/concerns"
    config.assets.enabled = true
    config.assets.paths << Rails.root.join('/app/assets/fonts')

    # Faker Gem
    config.autoload_paths += Dir[File.join(Rails.root,
                                           'lib', 'faker', '*.rb')].each { |l| require l }
    # Helper Classes
    config.autoload_paths += Dir[File.join(Rails.root,
                                           'lib', 'dropshipper', '*.rb')].each { |l| require l }
    config.autoload_paths += Dir[File.join(Rails.root,
                                           'lib', 'supply', '**', '*.rb')].each { |l| require l }

    # Generators
    config.generators do |g|
      g.test_framework :rspec
      g.orm :active_record
    end

    # Stripe Configurations
    config.stripe.publishable_key = ENV['STRIPE_PUBLIC_KEY']
    config.stripe.secret_key = ENV['STRIPE_API_KEY']
    config.stripe.signing_secrets = [ENV['STRIPE_WEBHOOK_SECRET']]

    # ActiveSupport.halt_callback_chains_on_return_false = false
    # config.font_assets.origin = '*'

    initializer 'spree.register.calculators' do |app|
      app.config.spree.calculators.shipping_methods <<
        Spree::Calculator::Shipping::CategoryCalculator
    end
  end
end
