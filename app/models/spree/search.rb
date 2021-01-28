module Spree
  class Search
    class EmptyActiveRecordRelation < StandardError; end

    def initialize(options)
      @keyword = options[:keyword]
      @relation = options[:relation]
      @joins = options[:joins]
      @custom_joins = options[:custom_joins]
      raise EmptyActiveRecordRelation, relation.class unless @relation.respond_to?(:empty?)

      @query = QueryBuilder::Search
    end

    def like
      return default_records if associations.empty? ||
                                associated_records.empty?

      associated_records
    end

    private

    attr_reader :joins, :relation, :keyword, :query, :custom_joins

    def default_records
      relation_query = query.composite_like(joins.slice(relation_name))
      relation.where(relation_query, wildcard: query.wildcard(keyword))
    end

    def associated_records
      association_query = query.composite_like(joins, nil)
      # custom_association_query = query.composite_custom_join_like(joins)
      sql = relation.joins(*associations).where(
        association_query, wildcard: query.wildcard(keyword)
      )
      puts "#{sql.to_sql}".blue
      sql
    end

    def associations
      joins.keys - [relation_name]
    end

    def custom_associations
      sql = ''
      # JOIN spree_addresses AS t2 ON spree_orders.bill_address_id = t2.id
      custom_joins.each do |key, value|
        sql << "JOIN #{value[:table_name]} as #{key} "\
          "ON #{relation.table_name}.#{value[:foreign_key]} = "\
          "#{key}.id "
      end
      sql
    end

    def relation_name
      relation.table_name.split('_')[1].to_sym
    end
  end
end
