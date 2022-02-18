require "test_helper"

class FullMetalBody::SaveBlockedKeysServiceTest < ActiveSupport::TestCase
  setup do
    @controller_path = 'articles'
    @action_name = 'create'
    @blocked_keys = [
      %w[article title],
      %w[article content],
      %w[article tags 0],
      %w[article tags 1],
      %w[article tags 2],
    ]
  end

  test 'BlockedAction and BlockedKeys should be created when no data registered.' do
    assert_difference -> { FullMetalBody::BlockedAction.count} => 1,
                      -> { FullMetalBody::BlockedKey.count } => 5 do
      FullMetalBody::SaveBlockedKeysService.execute!(@controller_path, @action_name, @blocked_keys)
    end
  end

  test 'BlockedAction and BlockedKeys should not be created when data already registered.' do
    FullMetalBody::SaveBlockedKeysService.execute!(@controller_path, @action_name, @blocked_keys)

    assert_no_difference [
                           -> { FullMetalBody::BlockedAction.count},
                           -> { FullMetalBody::BlockedKey.count }] do
      FullMetalBody::SaveBlockedKeysService.execute!(@controller_path, @action_name, @blocked_keys)
    end
  end

  test 'BlockedKeys should be created when part of data already registered.' do
    FullMetalBody::SaveBlockedKeysService.execute!(@controller_path, @action_name, @blocked_keys)

    assert_difference -> { FullMetalBody::BlockedKey.count } => 2 do
      FullMetalBody::SaveBlockedKeysService.execute!(@controller_path, @action_name, [
        %w[article title],
        %w[article content],
        %w[article tags 0],
        %w[article tags 1],
        %w[article tags 2],
        %w[article tags 3],
        %w[article tags 4],
      ])
    end
  end




end
