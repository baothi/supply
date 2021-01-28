require 'shopify_api'

#
# Retry a ShopifyAPI request if an HTTP 429 (too many requests) is returned.
#
# ShopifyAPIRetry.retry { customer.update_attribute(:tags, "foo")  }
# ShopifyAPIRetry.retry(30) { customer.update_attribute(:tags, "foo") }
# c = ShopifyAPIRetry.retry { ShopifyAPI::Customer.find(id) }
#
# By Skye Shaw (https://gist.github.com/sshaw/6043fa838e1cecf9d902)

module ShopifyAPIRetry
  VERSION = '0.0.1'.freeze
  HTTP_RETRY_AFTER = 'Retry-After'.freeze

  def retry(seconds_to_wait = nil)
    raise ArgumentError, 'block required' unless block_given?
    raise ArgumentError, 'seconds to wait must be > 0' unless
        seconds_to_wait.nil? || seconds_to_wait.positive? # maybe enforce 2?

    result = nil
    retried = false

    begin
      result = yield
    rescue ActiveResource::ClientError => e
      # Not 100% if we need to check for code method, I think I saw a NoMethodError...
      raise unless !retried && e.response.respond_to?(:code) && e.response.code.to_i == 429

      puts "Ran into ShopifyAPI Rate Limit while executing".red

      seconds_to_wait ||= (e.response[HTTP_RETRY_AFTER] || 2).to_i
      sleep seconds_to_wait

      retried = true
      retry
    end
    puts "Succeeded! Retried: #{retried} Nil Result? #{result.nil?} ".yellow
    result
  end

  module_function :retry
end
