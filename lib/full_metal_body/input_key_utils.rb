# frozen_string_literal: true

module FullMetalBody
  module InputKeyUtils

    extend ActiveSupport::Concern

    private

    # Check if key is a numeric.
    # @param [String,Integer] key
    # @return [Boolean] (true, false)
    def key_numeric?(key)
      key.to_i.to_s == key || key.is_a?(Numeric)
    end

    # Divide the keys by the number representing the array.
    # @param [Array<String,Symbol>] keys
    # @return [Array<Array>] parent_keys and child_keys
    def separate_by_array_key(keys)
      idx = keys.find_index { |k| key_numeric?(k) }
      parent_keys, child_keys = keys.partition.with_index { |_, i| i <= idx }
      parent_keys.delete_at(-1) # parent_keys.last is unnecessary.
      return parent_keys, child_keys
    end

  end

end
