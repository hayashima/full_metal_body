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

    # 動的にホワイトリストを生成してマージしたものを返す
    # @return [ActiveSupport::HashWithIndifferentAccess] ホワイトリスト
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

    # ホワイトリストにキーの情報が載っていないかを確認する
    # @return [Boolean] 載っていなければtrueを返す。載っていたらfalseを返す。
    def keys_isnt_whitelisted?
      !@whitelist.dig(*@keys)
    end

    # キー情報から配列が含まれているかを確認する
    # @return [Boolean] 配列が含まれていたらtrueを返す。なければfalseを返す。
    def keys_include_array?(keys)
      !!keys.find_index { |k| key_numeric?(k) }
    end

    # valueの型情報を返す
    # @return [String] 型情報
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

    # 動的に配列のホワイトリストを生成する
    # @param [Array<String,Symbol>] keys キーの配列
    # @option [Array<String,Symbol>] prefix_keys 配列がネストしていた場合に、上位キー情報を渡す
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
        # が、@whitelistにマージされる
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
        # が、@whitelistにマージされる
        @whitelist.bury!((parent_keys + ['properties', child_keys.first, 'type']), type_definition_by_value)
      elsif keys_include_array?(child_keys)
        # ケース1:シンプルな2次元配列
        # 1周目
        # keys = ["models", 0, 0]
        # prefix_keys # => []
        # parent_keys # => ["models"]
        # child_keys # => [0]
        # まだ配列があるので再帰（ここ）に突入
        # generate_whitelist_for_array([0], ["models", "properties"])
        #   2周目
        #   keys = [0]
        #   prefix_keys = ["models", "properties"]
        #   parent_keys = ["models", "properties"]
        #   child_keys = []
        #   `if child_keys.empty?` に入る
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
        #   が、@whitelistにマージされる
        #
        # ケース2:配列内のオブジェクトが更に配列を持っている
        # 1周目
        # keys = ["models", 0, "model_ids", 0]
        # prefix_keys # => []
        # parent_keys # => ["models"]
        # child_keys # => ["model_ids", 0]
        # まだ配列があるので再帰（ここ）に突入
        # generate_whitelist_for_array(["model_ids", 0], ["models", "properties"])
        #   2周目
        #   keys = ["model_ids", 0]
        #   prefix_keys = ["models", "properties"]
        #   parent_keys = ["models", "properties", "model_ids"]
        #   child_keys = []
        #   `if child_keys.empty?` に入る
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
        #   が、@whitelistにマージされる
        #
        # ケース3:配列内のオブジェクトが更に配列を持っていて、その中にオブジェクトがある
        # 1周目
        # keys = ["articles", 0, "comments", 0, "content"]
        # prefix_keys # => []
        # parent_keys # => ["articles"]
        # child_keys # => ["comments", 0, "content"]
        # まだ配列があるので再帰（ここ）に突入
        # generate_whitelist_for_array(["comments", 0, "content"], ["articles", "properties"])
        #   2周目
        #   keys = ["comments", 0, "content"]
        #   prefix_keys = ["articles", "properties"]
        #   parent_keys = ["articles", "properties", "comments"]
        #   child_keys = ["content"]
        #   `elsif child_keys.size == 1 && !key_numeric?(child_keys.first)` に入る
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
        #   が、@whitelistにマージされる
        #
        # これより階層が深くでも再帰的に処理されるので問題なし
        generate_whitelist_for_array(child_keys, parent_keys + ['properties'])
      else
        # ここにくるケースは通常ないと思うので、来たらわかるようにしておきたい
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
