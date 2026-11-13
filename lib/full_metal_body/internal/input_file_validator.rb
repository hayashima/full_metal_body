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
        if options.key?(:allowed_extensions)
          value = options[:allowed_extensions]
          unless value.nil? || (value.is_a?(Array) && value.all? { |extension| extension.is_a?(String) && extension.match?(/\A\.[A-Za-z0-9][A-Za-z0-9.+_-]*\z/) })
            raise ArgumentError, ":allowed_extensions must be an Array of extensions"
          end
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
          return record.errors.add(attribute, :too_large_size)
        end

        if options[:allowed_extensions]
          extensions = options[:allowed_extensions].map(&:downcase)
          filename = value.original_filename.to_s
          return record.errors.add(attribute, :invalid_extension) if filename.include?("\0")

          filename = File.basename(filename).downcase
          return record.errors.add(attribute, :invalid_extension) unless extensions.any? { |extension| filename.end_with?(extension) }
        end

      end

    end

  end
end
