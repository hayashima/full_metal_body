# frozen_string_literal: true

require 'full_metal_body/input_validation'
require 'full_metal_body/services/save_blocked_keys_service'
require 'full_metal_body/whitelist_writer'

module FullMetalBody
  module InputValidationAction

    extend ActiveSupport::Concern

    RAILS_KEYS = %w(controller action format).map(&:freeze).freeze
    MAX_BLOCKED_KEYS_COUNT = 3

    included do
      before_action :validate_params

      unless respond_to?(:current_user, true)
        class_eval do
          def current_user
            nil
          end
        end
      end
    end

    private

    #
    # パラメーターの検証を行う
    #
    def validate_params
      blocked_keys = []
      whitelist = get_whitelist

      hash_keys(params.to_unsafe_h).each do |key|
        next if RAILS_KEYS.include?(key.join('.'))

        value = params.dig(*key)
        if permit_all_params?(key, whitelist)
          dynamic_whitelist_generator = DynamicWhitelistGenerator.new(key, value, whitelist)
          whitelist = dynamic_whitelist_generator.execute!
          # whitelistの参照を掴んでいるのでGCされなさそうな気がするのでnilで開放する
          # rubocop:disable Lint/UselessAssignment
          dynamic_whitelist_generator = nil
          # rubocop:enable Lint/UselessAssignment
        end

        valid, result = validate_each(key, value, whitelist)
        if valid
          if result.nil? && !permit_all_params?(key, whitelist)
            # ホワイトリスト外のとき、記録・カウントする
            record_blocked_key(key.join('.'))
            blocked_keys << key

            next if (ENV['USE_WHITELIST_COUNT_CHECK'] || '1') == '0'

            # ホワイトリスト外のキーのカウントチェックを使用する場合
            if blocked_keys.size > MAX_BLOCKED_KEYS_COUNT
              SaveBlockedKeysService.execute!(controller_path, action_name, blocked_keys)
              output_error(
                blocked_keys.to_s,
                "ホワイトリスト外のパラメータが#{MAX_BLOCKED_KEYS_COUNT}つより多い",
                )
              return nil
            end
          end
        else
          # 検証エラーのとき、中断する
          output_error(key.join('.'), result.details)
          return nil
        end
      end

      # ブロックされたキーがなければ処理終了
      return if blocked_keys.empty?

      SaveBlockedKeysService.execute!(controller_path, action_name, blocked_keys)

      # 開発環境では、ホワイトリストの自動生成および例外を発生させる
      # return unless Rails.env.development?

      WhitelistWriter.new(controller_path, action_name).write!(blocked_keys)
      raise StandardError, "#{blocked_keys} がホワイトリストに含まれていません。tmp/whitelist/#{controller_path} にひな形が生成されています。"
    end

    #
    # 値を順にバリデーションする
    #
    # @param [Array<String>] key キー
    # @param [Object] value バリュー
    # @param [Hash] whitelist ホワイトリスト
    #
    # @return [Boolean] バリデーションが成功したかどうか
    # @return [Hash, ActiveModel::Errors] 成功時：許可されているか、失敗時：エラー情報
    #
    def validate_each(key, value, whitelist)
      key_type = nil
      # valueがnilの場合に空配列になると入力検証のルールが無視されるので、nilの場合はnilを含んだ配列にする
      (value.nil? ? [nil] : Array(value)).flatten.each do |v|
        validation = InputValidation.new(key.map(&:to_s), v, whitelist)
        key_type = validation.key_type
        return false, validation.errors unless validation.valid?
      end
      return true, key_type
    end

    #
    # ハッシュをキーにばらす
    #
    # @param [Object] o オブジェクト
    # @param [Array<String>] key ハッシュのキーの保持
    # @param [Array<String>] result ばらした結果の保持
    #
    # @return [Array<String>] result ばらした結果
    #
    def hash_keys(o, key = [], result = [])
      case o
      when Hash
        o.each do |k, v|
          hash_keys(v, key + [k], result)
        end
      when Array
        o.each_with_index do |v, idx|
          hash_keys(v, key + [idx], result)
        end
      else
        result << key
      end
      result
    end

    #
    # ホワイトリストの取得
    #
    # @return [Hash] ホワイトリスト
    #
    def get_whitelist
      path = Rails.root.join('config', 'whitelist', "#{controller_path}.yml")
      return nil unless File.exist?(path)

      yaml = File.open(path, "r") do |file|
        YAML.safe_load(file)&.deep_stringify_keys
      end
      yaml&.dig(controller_name, action_name)
    end

    #
    # 検証エラーを出力する
    #
    # @param [String] key キー
    # @param [String] errors エラーに表示する文字列
    #
    def output_error(key, errors)
      error_message = <<~ERR
        Input validation error detected
          Process: #{controller_path}##{action_name}
          User: #{current_user&.id || '不明'}
          IP: #{request.remote_ip}
          Key: #{key}
          Errors: #{errors}
      ERR
      # TODO: Bugsnag以外でも対応できるようにしたい
      # Bugsnag.notify(error_message) if Rails.env.production?
      logger.error error_message
      head :bad_request
    end

    #
    # ホワイトリストに含まれないときに記録する
    #
    # @param [String] key キー
    #
    def record_blocked_key(key)
      process_name = "#{controller_path}##{action_name}"
      message = "Input validation warning ('#{key}' not include in whitelist for '#{process_name}')"
      logger.warn message
    end

    # 特定のキー以下のパラメーターを許可するかどうかを返す。
    # stringとしての検証は行うが、blocked keyとしては扱わないようにしたいため。
    # _permit_allにtrueが設定されていたら許可する
    #
    # @param [Array] keys パラメーターキー
    # @param [Hash] whitelist ホワイトリスト
    # @return [Boolean] 全て許可の項目があればtrueを返す。それ以外はfalseを返す
    def permit_all_params?(keys, whitelist)
      return false if whitelist.blank?

      keys.size.downto(1).any? { |i| whitelist.dig(*keys.first(i))&.fetch('_permit_all', false) }
    end

  end
end
