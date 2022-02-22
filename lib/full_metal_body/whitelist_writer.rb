# frozen_string_literal: true

require 'json'
require 'full_metal_body/deep_sort'
require 'full_metal_body/dynamic_whitelist_generator'
using FullMetalBody::DeepSort

module FullMetalBody

  class WhitelistWriter

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
      @data.deep_sort!
      File.open(save_path, "w") do |file|
        YAML.dump(@data, file)
      end
      FileUtils.chmod(0o777, save_path)
    end

    # Return path to store the whitelist.
    # @return [Pathname]
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

    # Dynamically generate whitelist from keys.
    # @param [Array] keys
    def update_data!(keys)
      whitelist = DynamicWhitelistGenerator.new(keys, 'string').execute!
      @data.bury!([controller_name, action_name], whitelist.to_hash)
    end

  end

end