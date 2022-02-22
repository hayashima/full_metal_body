# frozen_string_literal: true

module FullMetalBody
  class SaveBlockedKeysService

    # Save blocked_keys to the database using bulk insert.
    #
    # @param [String] controller_path
    # @param [String] action_name
    # @param [Array<Array<String>>] keys
    # @return [ActiveRecord::Result]
    def self.execute!(controller_path, action_name, blocked_keys)
      ApplicationRecord.transaction do
        blocked_action = BlockedAction.find_or_create_by!(controller: controller_path, action: action_name)
        attributes = blocked_keys.map { |key| { blocked_key: key } }
        now = Time.zone.now
        blocked_action.blocked_keys.create_with(
          created_at: now,
          updated_at: now,
        ).insert_all(attributes, returning: [:id], unique_by: [:blocked_action_id, :blocked_key])
      end
    end

  end

end
