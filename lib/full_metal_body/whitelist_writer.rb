# frozen_string_literal: true

require 'json'
require 'full_metal_body/deep_sort'
require 'full_metal_body/dynamic_whitelist_generator'
using FullMetalBody::DeepSort

module FullMetalBody
  # 入力値バリデーション用ホワイトリストに載っていなかったパラメータに関して、
  # 雛形を生成するためのクラス
  #
  # InputValidationAction で使われている

  class WhitelistWriter

    class << self

      # 指定したホワイトリストのyamlファイルをソートして保存する
      # @param [String] filename yamlファイル名
      def sort!(filename)
        file_path = Rails.root.join('config', 'whitelist', filename)
        whitelist = YAML.load_file(file_path)
        whitelist.deep_sort!
        File.open(file_path, "w") do |file|
          YAML.dump(whitelist, file)
        end
        FileUtils.chmod(0o777, file_path)
      end

      # HerokuのDataclipsから取得したBlockedKeysのjsonを既存のホワイトリストに登録する。
      # 既存のホワイトリストが存在しない場合は、新たに作成する。
      # DataclipsのURL: https://data.heroku.com/dataclips/glcsagcjsymascuiggunlhhflqin
      # @param [String] filename jsonファイル名
      def merge_from_json!(filename)
        json = JSON.parse(File.read(Rails.root.join(filename)))
        values_group_by_controller_path = json['values'].group_by(&:first)
        values_group_by_controller_path.each do |controller_path, rows|
          block_keys_group_by_action_name = rows.group_by { |row| row[1] }.transform_values { |v| v.map(&:last) }
          dynamic_whitelist_from_blocked_keys = block_keys_group_by_action_name.each_with_object({}) do |(action_name, blocked_keys), hash|
            blocked_keys.each do |keys|
              dynamic_whitelist = DynamicWhitelistGenerator.new(keys, 'string').execute!
              hash.bury!([controller_path.split('/').last, action_name], dynamic_whitelist.to_hash)
            end
          end
          file_path = Rails.root.join('config', 'whitelist', "#{controller_path}.yml")
          whitelist = File.exist?(file_path) ? YAML.load_file(file_path) : {}
          new_whitelist = dynamic_whitelist_from_blocked_keys.deep_merge(whitelist)
          new_whitelist.deep_sort!
          File.open(file_path, "w") do |file|
            YAML.dump(new_whitelist, file)
          end
          FileUtils.chmod(0o777, file_path)
        end
      end

    end

    # コンストラクタ
    # @param [String] controller_path
    # @param [String] action_name
    def initialize(controller_path, action_name)
      @controller_path = controller_path
      @action_name = action_name
      @data = {}
    end

    # @param [Array<Array>] blocked_keys
    def write!(blocked_keys)
      blocked_keys.each { |key| update_data!(key) }

      dir = File.dirname(save_path)
      FileUtils.mkdir_p(dir, mode: 0o777) unless Dir.exist?(dir)
      if File.exist?(save_path)
        whitelist = YAML.load_file(save_path)
        @data.deep_merge!(whitelist)
      end
      File.open(save_path, "w") do |file|
        YAML.dump(@data, file)
      end
      FileUtils.chmod(0o777, save_path)
    end

    # ホワイトリストを保存するパス情報を返す
    # @return [Pathname] パス情報
    def save_path
      @save_path ||= if Rails.env.test?
                       Rails.root.join('tmp', "test#{ENV.fetch('TEST_ENV_NUMBER', '')}", 'whitelist', "#{@controller_path}.yml")
                     else
                       Rails.root.join('tmp', 'whitelist', "#{@controller_path}.yml")
                     end
    end

    private

    attr_reader :action_name

    def controller_name
      @controller_path.split('/').last
    end

    # 渡されたkeysから動的にホワイトリストを生成する。
    # 型はstringなのでvalueに文字列を渡しておく。
    # @param [Array] keys
    def update_data!(keys)
      whitelist = DynamicWhitelistGenerator.new(keys, 'string').execute!
      @data.bury!([controller_name, action_name], whitelist.to_hash)
    end

  end

end