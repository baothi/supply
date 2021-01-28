DEFAULT_HOST = 'localhost'.freeze # 'dropshipper.dev'.freeze
DEFAULT_PORT = 31234

def switch_to_subdomain
  Capybara.app_host = "http://sample-store.#{DEFAULT_HOST}:#{DEFAULT_PORT}"
end

Capybara.javascript_driver = :poltergeist

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, js_errors: false, timeout: 600)
end

Capybara.default_host = "http://#{DEFAULT_HOST}"
Capybara.server_port = DEFAULT_PORT
Capybara.app_host = "http://#{DEFAULT_HOST}:#{Capybara.server_port}"

# host = 'http://sample-store.dropshipper.dev'
# Capybara.server_port = 31234
# Capybara.javascript_driver = :poltergeist
# Capybara.default_host = host
# Capybara.app_host = host

# Capybara::Webkit.configure do |c|
#   c.allow_url(host)
# end

RSpec.configure do |config|
  config.before(:each, type: :feature) do
    # switch_to_subdomain
  end
end
