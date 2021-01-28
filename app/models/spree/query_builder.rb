module Spree
  module QueryBuilder
    class Search
      def self.like(table, column)
        "spree_#{table}.#{column} iLIKE :wildcard "
      end

      def self.custom_like(table, column)
        "#{table}.#{column} iLIKE :wildcard "
      end

      def self.composite_like(joins, custom_joins = nil)
        main_query = (joins.map do |table, columns|
          next if columns.nil? || columns.empty?

          columns.map { |column| Search.like(table, column) }
        end).compact.join('OR ')
        return main_query if custom_joins.nil?

        secondary_query = composite_custom_join_like(custom_joins)
        puts "Secondary Query: #{secondary_query}".yellow
        main_query + 'OR ' + secondary_query
      end

      def self.wildcard(keyword)
        "%#{keyword}%"
      end

      def self.composite_custom_join_like(custom_joins)
        (custom_joins.map do |table, columns|
          next if columns.nil? || columns.empty?

          columns[:fields].map { |column| Search.custom_like(table, column) }
        end).compact.join('OR ')
      end
    end
  end
end
