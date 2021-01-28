# This purpose of this service is to ensure StackCommerce Provided CSV is valid
module StackCommerce
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
          batch_id order_num vendor_sku qty product_name sale_name stack_sku
          shipping_first_name shipping_last_name shipping_address_1
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
