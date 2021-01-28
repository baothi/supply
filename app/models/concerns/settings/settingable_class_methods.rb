# Inspired by spree/core/app/models/spree/preferences/preferable_class_methods.rb
module Settings
  module SettingableClassMethods
    def setting(name, type, *args)
      options = args.extract_options!
      options.assert_valid_keys(:default)
      default = options[:default]
      default = -> { options[:default] } unless default.is_a?(Proc)

      # cache_key will be nil for new objects, then if we check if there
      # is a pending preference before going to default
      define_method setting_getter_method(name) do
        settings.with_indifferent_access.fetch(name) do
          default.call
        end
      end

      define_method setting_setter_method(name) do |value|
        value = convert_setting_value(value, type)
        settings[name] = value

        # If this is an activerecord object, we need to inform
        # ActiveRecord::Dirty that this value has changed, since this is an
        # in-place update to the preferences hash.
        settings_will_change! if respond_to?(:settings_will_change!)
      end

      define_method setting_default_getter_method(name), &default

      define_method setting_type_getter_method(name) do
        type
      end
    end

    def setting_getter_method(name)
      "setting_#{name}".to_sym
    end

    def setting_setter_method(name)
      "setting_#{name}=".to_sym
    end

    def setting_default_getter_method(name)
      "setting_#{name}_default".to_sym
    end

    def setting_type_getter_method(name)
      "setting_#{name}_type".to_sym
    end
    end
  end
