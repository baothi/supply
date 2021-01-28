module Dropshipper
  class SkuHelper
    ALPHA_NUMERIC = 'alpha_numeric'.freeze unless self.const_defined?('ALPHA_NUMERIC')
    NUMERIC_ONLY = 'numeric_only'.freeze unless self.const_defined?('NUMERIC_ONLY')
    ALPHA_ONLY = 'alpha_only'.freeze unless self.const_defined?('ALPHA_ONLY')

    def self.generate_code(sku_type = ALPHA_NUMERIC, length = 5)
      case sku_type
      when ALPHA_NUMERIC
        code = Faker::Number.hexadecimal(length)
      when NUMERIC_ONLY
        code = Faker::Number.number(length)
      when ALPHA_ONLY
        o = [('a'..'z'), ('A'..'Z')].map(&:to_a).flatten
        code = (0...length).map { o[rand(o.length)] }.join
      else
        raise 'Invalid option passed to Dropshipper:::SkuHelper.generate_code'
      end
      # code = code.to_s.rjust(length, '0') if pad
      code.upcase
    end
  end
end
