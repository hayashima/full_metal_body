module FullMetalBody
  module Internal

    class ReasonableDateValidator < ActiveModel::EachValidator

      def validate_each(record, attribute, value)
        return if value.blank? || value.is_a?(Date)

        unless date_valid?(value)
          record.errors.add(attribute, :not_reasonable_date, value: value)
        end
      end

      def date_valid?(str)
        # Allow only slash and hyphen separators
        unless str.match?(%r{^\d{4}/\d{1,2}/\d{1,2}$|^\d{4}-\d{1,2}-\d{1,2}$})
          return false
        end

        !!Date.parse(str)
      rescue
        false
      end

    end
  end
end
