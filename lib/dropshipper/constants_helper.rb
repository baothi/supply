module Dropshipper
  class ConstantsHelper
    def self.create_klass_constant(obj_type, const_label, const_value)
      klass = obj_type.constantize
      klass.const_set(:"#{const_label.upcase}", const_value) unless
          klass.const_defined?(const_label.upcase)
    end

    # Helper for above
    def self.create_klass_constant_with_same_label_and_value(obj_type, const_value)
      self.create_klass_constant(obj_type, const_value, const_value)
    end

    def self.create_constant_from_collection(obj_type, collection_name, collection)
      klass = obj_type.constantize

      constant_array = []
      collection.each do |c|
        self.create_klass_constant_with_same_label_and_value(obj_type, c)
        constant_array << c
      end
      return if klass.const_defined?(collection_name.upcase)

      klass.const_set(:"#{collection_name.upcase}", constant_array)
    end
  end
end
