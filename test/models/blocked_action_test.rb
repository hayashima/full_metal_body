# frozen_string_literal: true

require "test_helper"

class FullMetalBody::BlockedActionTest < ActiveSupport::TestCase
  test "controller and action should be present." do
    blocked_action = FullMetalBody::BlockedAction.new
    assert_equal false, blocked_action.valid?
    assert_equal true, blocked_action.errors.of_kind?(:controller, :blank)
    assert_equal true, blocked_action.errors.of_kind?(:action, :blank)
  end

  test "it should be unique." do
    FullMetalBody::BlockedAction.create!(controller: 'home', action: 'index')
    blocked_action = FullMetalBody::BlockedAction.new(controller: 'home', action: 'index')
    assert_equal false, blocked_action.valid?
    assert_equal true, blocked_action.errors.of_kind?(:controller, :taken)
    assert_raises(ActiveRecord::RecordInvalid) do
      blocked_action.save!
    end
  end
end
