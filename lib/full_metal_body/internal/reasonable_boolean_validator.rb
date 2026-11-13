module FullMetalBody
  module Internal
    class ReasonableBooleanValidator < ActiveModel::EachValidator

      TRUE_VALUES = [true, "1", "t", "T", "true", "TRUE", "on", "ON"].to_set.freeze
      FALSE_VALUES = [false, "0", "f", "F", "false", "FALSE", "off", "OFF"].to_set.freeze

      def check_validity!
        %i[true_values false_values].each do |option|
          next unless options.key?(option)

          values = options[option]
          next if values.nil?

          unless values.is_a?(Array) && values.all?(String)
            raise ArgumentError, ":#{option} must be an Array of Strings"
          end
        end
      end

      def validate_each(record, attribute, value)
        true_values = options[:true_values] || TRUE_VALUES
        false_values = options[:false_values] || FALSE_VALUES
        valid_value = [true, false].include?(value) || true_values.include?(value) || false_values.include?(value)

        unless valid_value
          record.errors.add(attribute, :not_reasonable_boolean, value: value)
        end
      end

    end
  end
end
