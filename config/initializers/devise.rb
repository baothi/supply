Devise.setup do |config|
  config.secret_key = "d2c0e8a703615a282baf26607b4fd3f71f3aa8af64587ed1efb6a12011da7f6764c48929bd1cd115c00786521fe38fd6b806"
  config.authentication_keys = [:email]
  config.scoped_views = true

  config.omniauth :google_oauth2, ENV['GOOGLE_OAUTH_CLIENT_ID'],
                    ENV['GOOGLE_OAUTH_CLIENT_SECRET'],
                    { hd: ENV['HINGETO_DOMAIN'] }
end
