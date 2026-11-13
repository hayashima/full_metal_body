module FullMetalBody
  module Internal

    class ReasonableDateValidator < ActiveModel::EachValidator

      def validate_each(record, attribute, value)
        return if value.blank?

        date = value.is_a?(Date) ? value : parse_date(value)
        unless date && date_within_bounds?(date)
          record.errors.add(attribute, :not_reasonable_date, value: value)
        end
      end

      def parse_date(value)
        return unless value.is_a?(String)

        if options[:format]
          date = Date.strptime(value, options[:format])
          return date if date.strftime(options[:format]) == value

          return
        end

        return unless value.match?(%r{\A\d{4}/\d{1,2}/\d{1,2}\z|\A\d{4}-\d{1,2}-\d{1,2}\z})

        Date.parse(value)
      rescue ArgumentError, TypeError
        nil
      end

      def date_within_bounds?(date)
        minimum = Date.iso8601(options[:minimum]) if options[:minimum]
        maximum = Date.iso8601(options[:maximum]) if options[:maximum]

        (!minimum || date >= minimum) && (!maximum || date <= maximum)
      end

    end
  end
end
