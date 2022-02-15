# frozen_string_literal: true

require "test_helper"

class FullMetalBody::BlockedKeyTest < ActiveSupport::TestCase

  setup do
    @blocked_action = FullMetalBody::BlockedAction.create!(controller: 'home', action: 'index')
    @keys = %w(article comments 0 content).map(&:freeze).freeze
  end

  test "blocked_key should be present." do
    blocked_key = @blocked_action.blocked_keys.build
    assert_equal false, blocked_key.valid?
    assert_equal true, blocked_key.errors.of_kind?(:blocked_key, :blank)
  end

  test "it should be unique." do
    @blocked_action.blocked_keys.create!(blocked_key: @keys)
    blocked_key = @blocked_action.blocked_keys.build(blocked_key: @keys)
    assert_equal false, blocked_key.valid?
    assert_equal true, blocked_key.errors.of_kind?(:blocked_action, :taken)
    assert_raises(ActiveRecord::RecordInvalid) do
      blocked_key.save!
    end
  end
end
