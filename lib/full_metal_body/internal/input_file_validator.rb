
module FullMetalBody
  module Internal
    class InputFileValidator < ActiveModel::EachValidator

      DEFAULT_CONTENT_TYPES = '*'.freeze
      DEFAULT_FILE_SIZE = 100.megabytes

      def check_validity!
        if options[:content_type]
          value = options[:content_type]
          unless value.is_a?(String) || (value.is_a?(Array) && value.all?(String))
            raise ArgumentError, ":content_type must be String or Array<String>"
          end
        end
        if options[:file_size]
          value = options[:file_size]
          raise ArgumentError, ":file_size must be a non-negative Integer" unless value.is_a?(Integer) && value >= 0
        end
      end

      def validate_each(record, attribute, value)
        return if value.nil?

        content_types = options[:content_type] || DEFAULT_CONTENT_TYPES
        file_size = options[:file_size] || DEFAULT_FILE_SIZE

        # type
        unless value.is_a? ActionDispatch::Http::UploadedFile
          return record.errors.add(attribute, :file_wrong_type, value: value)
        end

        # content type
        if content_types != '*' && Array(content_types).exclude?(value.content_type)
          return record.errors.add(attribute, :invalid_content_type)
        end

        # file size
        if value.size > file_size
          record.errors.add(attribute, :too_large_size)
        end
      end

    end

  end
end
