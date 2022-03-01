# frozen_string_literal: true

module FullMetalBody
  class SaveBlockedKeysService

    class << self

      # Save blocked_keys to the database using bulk insert.
      #
      # @param [String] controller_path
      # @param [String] action_name
      # @param [Array<Array<String>>] blocked_keys
      # @return [ActiveRecord::Result]
      def execute!(controller_path, action_name, blocked_keys)
        ApplicationRecord.transaction do
          blocked_action = BlockedAction.find_or_create_by!(controller: controller_path, action: action_name)
          now = Time.zone.now
          if rails_6_1_and_up?
            attributes = blocked_keys.map { |key| { blocked_key: key } }
            blocked_action.blocked_keys.create_with(
              created_at: now,
              updated_at: now,
              ).insert_all(attributes, returning: [:id], unique_by: [:blocked_action_id, :blocked_key])
          elsif rails_6_0?
            attributes = blocked_keys.map do |key|
              {
                blocked_action_id: blocked_action.id,
                blocked_key: key,
                created_at: now,
                updated_at: now,
              }
            end
            blocked_action.blocked_keys.insert_all(
              attributes,
              returning: [:id],
              unique_by: [:blocked_action_id, :blocked_key],
              )
          else
            blocked_keys.each { |key| blocked_action.blocked_keys.find_or_create_by(blocked_key: key) }
          end
        end
      end

      private

      def rails_6_1_and_up?
        Gem::Version.new(Rails.version) >= Gem::Version.new("6.1.0")
      end

      def rails_6_0?
        Rails::VERSION::MAJOR == 6 && Rails::VERSION::MINOR == 0
      end
    end
  end
end
