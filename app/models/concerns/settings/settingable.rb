# Inspired by spree/core/app/models/spree/settings/preferable.rb
# e.g. we can now do
# setting :shopify_price_updates, :boolean, default: true
module Settings
  module Settingable
    extend ActiveSupport::Concern

    included do
      # serialize :settings, HashSerializer

      extend Settings::SettingableClassMethods

      after_initialize do
        if has_attribute?(:settings) && !settings.nil?
          self.settings = default_settings.merge(settings)
        end
      end
    end

    def get_setting(name)
      has_setting! name
      send self.class.setting_getter_method(name)
    end

    def set_setting(name, value)
      has_setting! name
      send self.class.setting_setter_method(name), value
    end

    def setting_type(name)
      has_setting! name
      send self.class.setting_type_getter_method(name)
    end

    def setting_default(name)
      has_setting! name
      send self.class.setting_default_getter_method(name)
    end

    def has_setting!(name)
      raise NoMethodError, "#{name} setting not defined" unless has_setting? name
    end

    def has_setting?(name)
      respond_to? self.class.setting_getter_method(name)
    end

    def defined_settings
      methods.grep(/\Asetting_.*=\Z/).map do |pref_method|
        pref_method.to_s.gsub(/\Asetting_|=\Z/, '').to_sym
      end
    end

    def default_settings
      Hash[
          defined_settings.map do |setting|
            [setting, setting_default(setting)]
          end
      ]
    end

    def clear_settings
      settings.keys.each { |pref| settings.delete pref }
    end

    private

    def convert_setting_value(value, type)
      case type
      when :string, :text
        value.to_s
      when :password
        value.to_s
      when :decimal
        (value.presence || 0).to_s.to_d
      when :integer
        value.to_i
      when :boolean
        if value.is_a?(FalseClass) ||
           value.nil? ||
           value == 0 ||
           value =~ /^(f|false|0)$/i ||
           (value.respond_to?(:empty?) && value.empty?)
          false
        else
          true
        end
      when :array
        value.is_a?(Array) ? value : Array.wrap(value)
      when :hash
        case value.class.to_s
        when 'Hash'
          value
        when 'String'
          # only works with hashes whose keys are strings
          JSON.parse value.gsub('=>', ':')
        when 'Array'
          begin
            value.try(:to_h)
          rescue TypeError
            Hash[*value]
          rescue ArgumentError
            raise 'An even count is required when passing an array to be converted to a hash'
          end
        else
          value.class.ancestors.include?(Hash) ? value : {}
        end
      else
        value
      end
    end
  end
end
