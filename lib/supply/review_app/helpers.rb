module Supply
  module ReviewApp
    class Helpers
      def self.review_app?
        app_name.present?
      end

      def self.app_name
        ENV['HEROKU_APP_NAME']
      end

      def self.parent_app_name
        ENV['HEROKU_PARENT_APP_NAME']
      end

      def self.app_number
        return unless app_name

        number = app_name.match(/pr-(\d+)/i)
        return if number.nil?

        "PR-#{number[-1]}"
      end
    end
  end
end
