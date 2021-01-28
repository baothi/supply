# require 'sidekiq-status'

# Sidekiq::Client.reliable_push! unless Rails.env.test?

# Sidekiq.configure_client do |config|
#   # accepts :expiration (optional)
#   Sidekiq::Status.configure_client_middleware config, expiration: 1.hour
# end

# Sidekiq.configure_server do |config|
#   config.super_fetch!
#   config.reliable_scheduler!

#   config.periodic do |mgr|
#     mgr.register(
#       ENV['FINANCE_REPORT_CRONTAB'],
#       Csv::Export::ScheduledFinanceReportWorker,
#       retry: 2,
#       queue: 'csv_export'
#     )
#   end

#   Sidekiq::Status.configure_server_middleware config, expiration: 1.hour
#   Sidekiq::Status.configure_client_middleware config, expiration: 1.hour
# end
