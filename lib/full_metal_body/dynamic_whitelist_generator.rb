# frozen_string_literal: true

module FullMetalBody
  class DynamicWhitelistGenerator

    include InputKeyUtils

    # @param [Array<String,Symbol>] keys
    # @param [Object] value
    # @param [Hash] whitelist
    def initialize(keys, value, whitelist = {})
      @keys = keys
      @value = value
      @whitelist = whitelist
    end

    # Dynamically generate a whitelist and return a merged one.
    # @return [ActiveSupport::HashWithIndifferentAccess]
    def execute!
      if keys_isnt_whitelisted?
        if keys_include_array?(@keys)
          generate_whitelist_for_array(@keys)
        else
          @whitelist.bury!((@keys + ['type']), type_definition_by_value)
        end
      end
      @whitelist.with_indifferent_access
    end

    private

    # Check to see if the keys are on the whitelist.
    # @return [Boolean] (true, false)
    def keys_isnt_whitelisted?
      !@whitelist.dig(*@keys)
    end

    # Check to see if the keys contain the array index.
    # @return [Boolean] (true, false)
    def keys_include_array?(keys)
      !!keys.find_index { |k| key_numeric?(k) }
    end

    # Return type-definition of value.
    # @return [String] Type-definition
    def type_definition_by_value
      case @value
      when Numeric
        'number'
      when Date
        'date'
      when TrueClass, FalseClass
        'boolean'
      else
        'string'
      end
    end

    # Dynamically generate an array whitelist.
    # @param [Array<String,Symbol>] keys
    # @option [Array<String,Symbol>] prefix_keys
    # @raise [DynamicWhitelistGenerator::ParseArrayError]
    def generate_whitelist_for_array(keys, prefix_keys = [])
      parent_keys, child_keys = separate_by_array_key(keys)
      parent_keys = prefix_keys + parent_keys
      @whitelist.bury!((parent_keys + ['type']), 'array')
      if child_keys.empty?
        # keys = ["pref_ids", 0]
        # prefix_keys # => []
        # parent_keys # => ["pref_ids"]
        # child_keys # => []
        # {
        #   "pref_ids" => {
        #     "type" => "array",
        #     "properties" => {
        #        "type" => type_definition_by_value
        #     }
        #   }
        # }
        @whitelist.bury!((parent_keys + ['properties', 'type']), type_definition_by_value)
      elsif child_keys.size == 1 && !key_numeric?(child_keys.first)
        # keys = ["models", 0, "model_id"]
        # prefix_keys # => []
        # parent_keys # => ["models"]
        # child_keys # => ["model_id"]
        # {
        #   "models" => {
        #     "type" => "array",
        #     "properties" => {
        #       "model_id" => {
        #         "type" => type_definition_by_value
        #       }
        #     }
        #   }
        # }
        @whitelist.bury!((parent_keys + ['properties', child_keys.first, 'type']), type_definition_by_value)
      elsif keys_include_array?(child_keys)
        # case 1: 2D array
        # Lap 1
        # keys = ["models", 0, 0]
        # prefix_keys # => []
        # parent_keys # => ["models"]
        # child_keys # => [0]
        # generate_whitelist_for_array([0], ["models", "properties"])
        #   Lap 2
        #   keys = [0]
        #   prefix_keys = ["models", "properties"]
        #   parent_keys = ["models", "properties"]
        #   child_keys = []
        #   Enter `if child_keys.empty?`
        #   {
        #     "models" => {
        #       "type" => "array",
        #       "properties" => {
        #         "type" => "array",
        #         "properties" => {
        #           "type" => type_definition_by_value
        #         }
        #       }
        #     }
        #   }
        #
        # case 2: An object in an array has a further array.
        # Lap 1
        # keys = ["models", 0, "model_ids", 0]
        # prefix_keys # => []
        # parent_keys # => ["models"]
        # child_keys # => ["model_ids", 0]
        # generate_whitelist_for_array(["model_ids", 0], ["models", "properties"])
        #   Lap 2
        #   keys = ["model_ids", 0]
        #   prefix_keys = ["models", "properties"]
        #   parent_keys = ["models", "properties", "model_ids"]
        #   child_keys = []
        #   Enter `if child_keys.empty?`
        #   {
        #     "models" => {
        #       "type" => "array",
        #       "properties" => {
        #         "model_ids" => {
        #           "type" => "array",
        #           "properties" => {
        #             "type" => type_definition_by_value
        #           }
        #         }
        #       }
        #     }
        #   }
        #
        # case 3: The object in the array has a further array, and the object in the array
        # Lap 1
        # keys = ["articles", 0, "comments", 0, "content"]
        # prefix_keys # => []
        # parent_keys # => ["articles"]
        # child_keys # => ["comments", 0, "content"]
        # generate_whitelist_for_array(["comments", 0, "content"], ["articles", "properties"])
        #   Lap 2
        #   keys = ["comments", 0, "content"]
        #   prefix_keys = ["articles", "properties"]
        #   parent_keys = ["articles", "properties", "comments"]
        #   child_keys = ["content"]
        #   Enter `elsif child_keys.size == 1 && !key_numeric?(child_keys.first)`
        #   {
        #     "articles" => {
        #       "type" => "array",
        #       "properties" => {
        #         "comments" => {
        #           "type" => "array",
        #           "properties" => {
        #             "content" => {
        #               "type" => type_definition_by_value
        #             }
        #           }
        #         }
        #       }
        #     }
        #   }
        generate_whitelist_for_array(child_keys, parent_keys + ['properties'])
      else
        # Normally, there are no cases that come here.
        # But if it should come, raise Exception.
        invalid_keys = prefix_keys + keys
        invalid_keys.delete('properties')
        raise DynamicWhitelistGenerator::ParseArrayError.new("Invalid keys", invalid_keys)
      end
    end

    class ParseArrayError < StandardError

      # @param [String] message
      # @param [Array<String,Symbol>] keys
      def initialize(message, keys)
        @keys = keys
        super("#{message}: #{@keys}")
      end

    end

  end

end
