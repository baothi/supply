# This purpose of this service is to ensure Karmaloop Provided CSV is valid
module Karmaloop
  module Order
    class Validator
      def initialize(opts = {})
        validate(opts)
        @lines = opts[:lines]
      end

      def validate(opts)
        raise 'Invalid Lines from CSV' if
            opts[:lines].blank? || opts[:lines].empty?
      end

      def valid_line?(line)
        puts "#{line}".blue

        keys = %i(
          invoice_id quantity title color size
          first_name last_name address1
          city state zip country
        )

        keys.each do |key|
          raise "#{key} is not set for #{line}" if line[key].blank?
        end
      end

      def perform
        begin
          @lines.each do |line|
            valid_line?(line)
          end
        rescue => ex
          puts "Invalid CSV: #{ex}".red
          return false
        end
        true
      end
    end
  end
end
