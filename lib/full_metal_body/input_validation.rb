# frozen_string_literal: true

require 'full_metal_body/input_key_utils'
require 'full_metal_body/internal/input_file_validator'
require 'full_metal_body/internal/input_string_validator'
require 'full_metal_body/internal/reasonable_boolean_validator'
require 'full_metal_body/internal/reasonable_date_validator'

module FullMetalBody
  class InputValidation

    include InputKeyUtils
    include ActiveModel::Validations

    attr_accessor :key, :value, :key_type

    validates :key, "full_metal_body/internal/input_string": true, if: :check_key?

    # @param [Array<String, Symbol>] key
    # @param [Object] value
    # @param [Hash] whitelist
    def initialize(key, value, whitelist)
      @key = key
      @value = value
      set_key_type(whitelist)
      if value_validate
        class_eval %(
        validates :value, #{value_validate} # validates :value, input_string: true
      ), __FILE__, __LINE__ - 2
      end
    end

    private

    # Whether to validate the key
    #
    # @return [Boolean] (true, false)
    def check_key?
      !@key_type
    end

    # Which validator to validate the value with
    #
    # @return [String] validator type
    def value_validate
      if @key_type.nil?
        if @value.is_a?(ActionDispatch::Http::UploadedFile)
          return "'full_metal_body/internal/input_file': true"
        end

        return "'full_metal_body/internal/input_string': true"
      end

      case @key_type['type']
      when 'string'
        options = @key_type['options']&.symbolize_keys || true
        "'full_metal_body/internal/input_string': #{options}"
      when 'number'
        options = @key_type['options']&.symbolize_keys || { allow_blank: true }
        if @value.is_a?(Numeric)
          "numericality: #{options}"
        else
          "'full_metal_body/internal/input_string': true, numericality: #{options}"
        end
      when 'date'
        if @value.is_a?(Date)
          "'full_metal_body/internal/reasonable_date': true"
        else
          "'full_metal_body/internal/input_string': true, 'full_metal_body/internal/reasonable_date': true"
        end
      when 'file'
        options = @key_type['options']&.symbolize_keys || true
        "'full_metal_body/internal/input_file': #{options}"
      when 'boolean'
        options = @key_type['options']&.symbolize_keys || true
        if [TrueClass, FalseClass].any? { |klass| @value.is_a?(klass) }
          "'full_metal_body/internal/reasonable_boolean': #{options}"
        else
          "'full_metal_body/internal/input_string': true, 'full_metal_body/internal/reasonable_boolean': #{options}"
        end
      end
    end

    # Set type-definition to @key_type
    #
    # @param [Hash] whitelist
    def set_key_type(whitelist)
      return @key_type = nil if whitelist.nil?

      # When ype-definition by key is exists in whitelist
      return @key_type = whitelist.dig(*@key) if has_type?(whitelist.dig(*@key))

      # When @key has the index number of the array
      if @key.find_index { |k| key_numeric?(k) }
        result = get_key_type_recursively(@key, whitelist)
        return @key_type = result if has_type?(result)
      end

      # When no type-definition by key in whitelist
      @key_type = nil
    end

    # Search type-definition by key recursively from whitelist
    #
    # @param [Array<String>] keys
    # @param [Hash] whitelist
    #
    # @return [Hash, NilClass] type-definition by key
    def get_key_type_recursively(keys, whitelist)
      parent_keys, child_keys = separate_by_array_key(keys)
      parent = parent_keys.empty? ? whitelist : whitelist.dig(*parent_keys)

      if parent['type'] == 'array'
        if child_keys.empty?
          # { type: array, properties: { type: string } }
          parent['properties']
        elsif parent['properties'].dig(*child_keys)
          # { type: array, properties: { hoge: { type: string } } }
          parent['properties'].dig(*child_keys)
        elsif parent.dig('properties', 'type') == 'array'
          # { type: array, properties: { type: array, properties: { ... } } }
          get_key_type_recursively(child_keys, parent['properties'])
        elsif parent.dig('properties', child_keys.first, 'type') == 'array'
          # { type: array, properties: { hoge: { type: array, properties: { ... } } } }
          first_key = child_keys.shift
          get_key_type_recursively(child_keys, parent.dig('properties', first_key))
        else
          nil
        end
      else
        nil
      end
    end

    # Whether or not the item has a type attribute.
    #
    # @param [Object] item
    #
    # @return [Boolean] (true, false)
    def has_type?(item)
      return false unless item.is_a?(Hash)

      %w(string number date file boolean).include?(item['type'])
    end

  end

end
