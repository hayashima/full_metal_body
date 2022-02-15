# frozen_string_literal: true

module FullMetalBody
  class BlockedKey < ActiveRecord::Base

    belongs_to :blocked_action

    validates :blocked_key, presence: true
    validates :blocked_action, uniqueness: { scope: :blocked_key }

  end
end
