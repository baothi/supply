module Hingeto
  class Dropshipper
    def self.development?
      ENV['DROPSHIPPER_ENV'] == 'development' || ENV['DROPSHIPPER_ENV'].nil?
    end

    def self.staging_or_development?
      ENV['DROPSHIPPER_ENV'] == 'development' || ENV['DROPSHIPPER_ENV'] == 'staging' ||
        ENV['DROPSHIPPER_ENV'].nil?
    end

    def self.production?
      ENV['DROPSHIPPER_ENV'] == 'production'
    end

    # Helper to ensure we don't accidentally run against real production if we happen
    # to have changed env variable to run against real production
    def self.dangerous_environment?
      ENV['DROPSHIPPER_ENV'] == 'production' || Rails.env.production?
    end

    def self.format_date(datetime, _opts = {})
      datetime.strftime("#{datetime.day.ordinalize} %b %Y") if datetime.is_a? Time
    end
  end
end
