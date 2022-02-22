module FullMetalBody
  module Internal
    class ReasonableBooleanValidator < ActiveModel::EachValidator

      TRUE_VALUES = [true, "1", "t", "T", "true", "TRUE", "on", "ON"].to_set.freeze
      FALSE_VALUES = [false, "0", "f", "F", "false", "FALSE", "off", "OFF"].to_set.freeze

      def validate_each(record, attribute, value)
        unless [TRUE_VALUES, FALSE_VALUES].any? { |b| b.include?(value) }
          record.errors.add(attribute, :not_reasonable_boolean, value: value)
        end
      end

    end
  end
end
