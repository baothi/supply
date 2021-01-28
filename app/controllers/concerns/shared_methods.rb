# methods defined here will be available in controllers, views and rspec tests
module SharedMethods
  extend ActiveSupport::Concern

  def google_analytics_client_id
    google_analytics_cookie.gsub(/^GA\d\.\d\./, '')
  end

  def google_analytics_cookie
    cookies['_ga'] || ''
  end
end
