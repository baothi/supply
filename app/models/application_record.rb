class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.all_polymorphic_types(name)
    @poly_hash ||= {}.tap do |hash|
      Rails.application.eager_load!
      ApplicationRecord.descendants.each do |klass|
        klass.reflect_on_all_associations(:has_many).select { |r| r.options[:as] }.each do |reflect|
          (hash[reflect.options[:as]] ||= []) << klass.name
        end
      end
    end
    @poly_hash[name.to_sym]&.uniq
  end
end
