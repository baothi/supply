# require 'simplecov'
# require 'coveralls'
#Coveralls.wear!

# SimpleCov.start 'rails' do
#   add_filter '/spec/'
#   add_filter '/config/'
#   add_filter '/vendor/'
#   add_filter '/test/'
# end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.shared_context_metadata_behavior = :apply_to_host_groups
end
