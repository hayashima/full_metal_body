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

    def validate_params
      blocked_keys = []
      whitelist = get_whitelist

      hash_keys(params.to_unsafe_h).each do |key|
        next if RAILS_KEYS.include?(key.join('.'))

        value = params.dig(*key)
        if permit_all_params?(key, whitelist)
          dynamic_whitelist_generator = DynamicWhitelistGenerator.new(key, value, whitelist)
          whitelist = dynamic_whitelist_generator.execute!
          # rubocop:disable Lint/UselessAssignment
          dynamic_whitelist_generator = nil
          # rubocop:enable Lint/UselessAssignment
        end

        valid, result = validate_each(key, value, whitelist)
        if valid
          if result.nil? && !permit_all_params?(key, whitelist)
            record_blocked_key(key.join('.'))
            blocked_keys << key

            next if (ENV['USE_WHITELIST_COUNT_CHECK'] || '1') == '0'

            if blocked_keys.size > MAX_BLOCKED_KEYS_COUNT
              SaveBlockedKeysService.execute!(controller_path, action_name, blocked_keys)
              output_error(
                blocked_keys.to_s,
                "Unknown parameters existed over #{MAX_BLOCKED_KEYS_COUNT}.",
                )
              return nil
            end
          end
        else
          output_error(key.join('.'), result.details)
          return nil
        end
      end

      return if blocked_keys.empty?

      SaveBlockedKeysService.execute!(controller_path, action_name, blocked_keys)

      return unless Rails.env.development?

      WhitelistWriter.new(controller_path, action_name).write!(blocked_keys)
      raise StandardError, "#{blocked_keys} are not included in whitelist. A template has been created in 'tmp/whitelist/#{controller_path}'"
    end

    # Validate with whitelist
    #
    # @param [Array<String>] key
    # @param [Object] value
    # @param [Hash] whitelist
    #
    # @return [Boolean] (true, false)
    # @return [Hash, ActiveModel::Errors] In success: Type definition. In failure: Error infos.
    def validate_each(key, value, whitelist)
      key_type = nil
      (value.nil? ? [nil] : Array(value)).flatten.each do |v|
        validation = InputValidation.new(key.map(&:to_s), v, whitelist)
        key_type = validation.key_type
        return false, validation.errors unless validation.valid?
      end
      return true, key_type
    end

    # Get hash keys recursively.
    #
    # @param [Object] obj object
    # @param [Array<String>] key
    # @param [Array<String>] result
    #
    # @return [Array<String>] result
    #
    def hash_keys(obj, key = [], result = [])
      case obj
      when Hash
        obj.each do |k, v|
          hash_keys(v, key + [k], result)
        end
      when Array
        obj.each_with_index do |v, idx|
          hash_keys(v, key + [idx], result)
        end
      else
        result << key
      end
      result
    end

    #
    # Get a whitelist from config/whitelist/**/*.yml
    #
    # @return [Hash] Whitelist
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
    # Output validation errors
    #
    # @param [String] key
    # @param [String] errors
    #
    def output_error(key, errors)
      error_message = <<~ERR
        Input validation error detected
          Process: #{controller_path}##{action_name}
          User: #{current_user&.id || 'unknown'}
          IP: #{request.remote_ip}
          Key: #{key}
          Errors: #{errors}
      ERR
      # TODO: I want to be able to handle more than just Bugsnag.
      if Rails.env.production?
        Bugsnag.notify(error_message) if defined?(Bugsnag)
      end
      logger.error error_message
      head :bad_request
    end

    # Logging key and process_name when key is not included in whitelist.
    #
    # @param [String] key
    #
    def record_blocked_key(key)
      process_name = "#{controller_path}##{action_name}"
      message = "Input validation warning ('#{key}' not include in whitelist for '#{process_name}')"
      logger.warn message
    end

    # Permit all parameters if '_permit_all: true' is existed.
    #
    # @param [Array<String,Symbol>] keys
    # @param [Hash] whitelist
    # @return [Boolean] (true, false)
    def permit_all_params?(keys, whitelist)
      return false if whitelist.blank?

      keys.size.downto(1).any? { |i| whitelist.dig(*keys.first(i))&.fetch('_permit_all', false) }
    end

  end
end
