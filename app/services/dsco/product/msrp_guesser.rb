# This module takes in a CSV and spits out another with the correct values.
# In production, FifthSun = fifth-sun-519001be-7c2a-4101-9071-40af9ac16c38
module Dsco
  module Product
    class MsrpGuesser
      # include ImportableJob

      attr_accessor :msrp, :status

      def initialize
        @msrp = nil
        @status = nil
      end

      def perform(row)
        begin
          @msrp = determine_dsco_price(row)
          @status = msrp.present?
        rescue => e
          puts "#{e}"
          Rollbar.error(e)
          nil
        end
      end

      # These prices are based on Historical observations made by Ismail
      # from past files.
      def determine_dsco_price(variant_hash)
        category = variant_hash[:category]
        size = variant_hash[:size]
        current_msrp = variant_hash[:msrp]
        return current_msrp if current_msrp.present?

        case category.parameterize
        when 't-shirt'
          if size.include?('LT')
            return 39.99
          else
            return 25.99
          end
        when 'crew-fleece'
          if size.include?('LT')
            return 49.99
          else
            return 44.99
          end
        when 'racerback-tank', 'racer-back-tank'
          return 25.99
        when 'baseball-tee'
          return 39.99
        when 'cowl-neck'
          return 44.99
        when 'festival-muscle-tank'
          return 29.99
        when 'hooded-fleece'
          return 47.99
        when 'long-sleeve-shirt'
          return 31.99
        when 'scoop-neck-w-drop-tail'
          return 31.99
        when 'tank', 'v-tank'
          return 25.99
        else
          return nil
        end
      end
    end
  end
end
