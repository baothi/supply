source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.7.2'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.0.3', '>= 6.0.3.4'
# Use postgresql as the database for Active Record
gem 'pg', '>= 0.18', '< 2.0'
# Use Puma as the app server
gem 'puma', '~> 4.1'
# Use SCSS for stylesheets
gem 'sass-rails', '>= 6'
# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
gem 'webpacker', '~> 4.0'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.7'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.2', require: false

# Fontawsome
gem 'font-awesome-sass', '~> 5.12.0'
# gem 'simple_form'
gem 'sprockets', '~> 3.7'

gem 'paper_trail'
# Address
gem 'carmen'
gem 'country_select'

gem 'omniauth-google-oauth2'

# Fake Data
# faker-ruby
gem 'faker', :git => 'https://github.com/faker-ruby/faker.git', :branch => 'master'
gem 'ffaker'

gem 'scss_lint', require: false

# Sftp
gem 'net-sftp'
# Friendly IDs
gem 'friendly_id', '~> 5.3.0'
# Feature Management
gem 'flipper'
gem 'flipper-redis'
gem 'flipper-ui'

# Encrypted Attributes
gem 'attr_encrypted'

gem 'colorize'

# Stripe payment initeration
gem 'stripe'
gem 'stripe-rails'
gem 'stripe-ruby-mock', '~> 3.0.1', :require => 'stripe_mock'

gem 'graphql-client'
gem 'shopify-api-throttle', git: 'https://github.com/hingeto/shopify-api-throttle'
gem 'shopify_api'

# #Spree
gem 'spree', '~> 4.0'
gem 'spree_auth_devise', '~> 4.0.0'
gem 'spree_gateway', '~> 3.7'
gem 'devise', github: 'heartcombo/devise', branch: 'ca-omniauth-2'

# Browser Detection
gem "browser", require: "browser/browser"
# File attachments
gem 'aws-sdk', '~> 3.0', '>= 3.0.1'
gem 'paperclip', '~> 6.1'
# Background Jobs
gem 'sidekiq', '~> 6.1', '>= 6.1.3'
gem 'sidekiq-status'
# Pagination
gem 'bootstrap'
gem 'bootstrap4-kaminari-views'
gem 'kaminari'

gem 'acts_as_follower',
    git: 'https://github.com/tcocca/acts_as_follower',
    branch: 'master'

# Excel Library
gem 'roo', '~> 2.8', '>= 2.8.3'

# Excel generation
gem 'caxlsx'
gem 'caxlsx_rails'
# Depedency by the above two.
gem 'rubyzip', '~> 2.3'

# Exception / Logging
gem 'rollbar'

gem 'activeadmin'
gem 'bootstrap_progressbar'
gem 'formadmin'
gem 'select2-rails'
gem 'smarter_csv'

# PDF Generation
gem 'prawn'
gem 'prawn-table'

# Analytics
gem 'analytics-ruby', require: 'segment'

gem 'pretender'

gem 'algoliasearch-rails'

# Style Guides
gem 'rubocop', '~> 1.8', '>= 1.8.1', require: false
gem 'rubocop-rspec', '~> 2.1'

# Rack
gem 'cloudinary'
gem 'rack-cors', require: 'rack/cors'

# Product Data / Validation
gem 'ean'

gem 'business_time'
gem 'scenic'

# Global Hingeto Cache
gem 'mongoid'
gem 'mongoid_search'

# Profiling
gem 'scout_apm'
# gem 'skylight', '4.0.0.beta'

# JSON Editor
gem 'jsoneditor-rails'

gem 'wicked'

gem 'activerecord-nulldb-adapter'

gem 'dotenv-rails'
gem 'aasm'
gem 'rack-mini-profiler', require: ['enable_rails_patches']
group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'factory_bot_rails'
  gem 'parallel_tests'
  gem 'pry-nav'
  gem 'pry-rails'
  gem 'rb-readline'

  # Insght into performance
  gem 'meta_request'
  # Letter Opener
  gem 'letter_opener_web'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'

  # gem 'coveralls', require: false
  gem 'database_cleaner'

  gem 'poltergeist'

  # gem 'shoulda-callback-matchers'
  # gem 'shoulda-matchers'
  gem 'railroady'
  gem 'rails-erd'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '~> 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 2.15'
  gem 'selenium-webdriver'
  # Easy installation and use of web drivers to run system tests with browsers
  gem 'webdrivers'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
