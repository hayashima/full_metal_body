# frozen_string_literal: true

module FullMetalBody
  module InputKeyUtils

    extend ActiveSupport::Concern

    private

    # keyが数値であるかどうかを確認する
    # @param [String|Integer] key
    # @return [Boolean] 数値と認められる文字列か数字であればtrueを返す
    def key_numeric?(key)
      key.to_i.to_s == key || key.is_a?(Numeric)
    end

    # keysを配列を表す数字があったところで分割する
    # @param [Array<String|Symbol>] keys
    # @return [Array<Array>] 親を表すkeysと子を表すkeys
    def separate_by_array_key(keys)
      idx = keys.find_index { |k| key_numeric?(k) }
      parent_keys, child_keys = keys.partition.with_index { |_, i| i <= idx }
      parent_keys.delete_at(-1) # parent_keysの最後の値は数字なので削除する
      return parent_keys, child_keys
    end

  end

end
