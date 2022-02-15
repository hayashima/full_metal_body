# frozen_string_literal: true

module FullMetalBody
  class BlockedAction < ActiveRecord::Base

    has_many :blocked_keys, dependent: :destroy

    validates :controller, presence: true, uniqueness: { scope: :action }
    validates :action, presence: true

  end
end
