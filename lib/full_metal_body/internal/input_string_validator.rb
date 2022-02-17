module FullMetalBody
  module Internal

    class InputStringValidator < ActiveModel::EachValidator

      DEFAULT_MAX_LENGTH = 1024

      def check_validity!
        if options[:max_length]
          value = options[:max_length]
          raise ArgumentError, ":max_length must be a non-negative Integer" unless value.is_a?(Integer) && value >= 0
        end
      end

      def validate_each(record, attribute, value)
        return if value.nil?

        if value.is_a?(Array)
          value.each do |v|
            validate_value(record, attribute, v.dup)
          end
        else
          validate_value(record, attribute, value.dup)
        end
      end

      def validate_value(record, attribute, value)
        max_length = options[:max_length] || DEFAULT_MAX_LENGTH

        # type
        unless value.is_a? String
          return record.errors.add(attribute, :wrong_type, value: value)
        end

        # length
        if value.size > max_length
          return record.errors.add(attribute, :too_long, value: byteslice(value), count: value.size)
        end

        # encoding
        original_encoding = value.encoding.name
        unless value.force_encoding('UTF-8').valid_encoding?
          return record.errors.add(attribute, :wrong_encoding, value: byteslice(value), encoding: original_encoding)
        end

        # cntrl
        # 改行コードと水平タブを置換して消す（垂直タブはNG）
        value = value.gsub(/\R|\t/, '')
        if /[[:cntrl:]]/.match?(value)
          record.errors.add(attribute, :include_cntrl, value: byteslice(value))
        end
      end

      def byteslice(value)
        value.byteslice(0, 1024)
      end

    end
  end
end
