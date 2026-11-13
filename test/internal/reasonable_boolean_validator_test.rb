require "test_helper"

class FullMetalBody::Internal::ReasonableBooleanValidatorTest < ActiveSupport::TestCase

  teardown do
    @subject = nil
  end

  test 'it should passed when value is one of the default true values.' do
    [true, "1", "t", "T", "true", "TRUE", "on", "ON"].each do |value|
      @value = value
      @options = nil
      assert subject.valid?
      @subject = nil
    end
  end

  test 'it should passed when value is one of the default false values.' do
    [false, "0", "f", "F", "false", "FALSE", "off", "OFF"].each do |value|
      @value = value
      @options = nil
      assert subject.valid?
      @subject = nil
    end
  end

  test 'it should passed when value is in the configured true values.' do
    @value = 'yes'
    @options = { true_values: ['yes'] }
    assert subject.valid?
  end

  test 'it should not pass when value is only a substring of a configured true value.' do
    @options = { true_values: ['yes'] }
    ['y', 'es', ''].each do |value|
      @value = value
      assert_not subject.valid?
      @subject = nil
    end
  end

  test 'it should passed when value is in the configured false values.' do
    @value = 'no'
    @options = { false_values: ['no'] }
    assert subject.valid?
  end

  test 'it should not passed when value is not in the configured true values.' do
    @value = 'true'
    @options = { true_values: ['yes'] }
    assert_not subject.valid?
  end

  test 'it should raise when configured boolean values are not arrays of strings.' do
    {
      true_values: 'yes',
      false_values: 1,
    }.each do |option, value|
      @options = { option => value }
      error = assert_raises(ArgumentError) { subject }
      assert_equal ":#{option} must be an Array of Strings", error.message
      @subject = nil
    end
  end

  test 'it should raise when configured boolean value arrays contain non-strings.' do
    @options = { true_values: ['yes', true] }
    error = assert_raises(ArgumentError) { subject }
    assert_equal ':true_values must be an Array of Strings', error.message
  end

  test 'it should use default values when configured boolean values are nil.' do
    @options = { true_values: nil, false_values: nil }
    @value = 'true'
    assert subject.valid?
  end

  test 'it should passed when native boolean values are used with custom values.' do
    @options = { true_values: ['yes'], false_values: ['no'] }
    [true, false].each do |value|
      @value = value
      assert subject.valid?
      @subject = nil
    end
  end

  test 'it should not passed when value is not a boolean value.' do
    @value = 'maybe'
    @options = nil
    assert_not subject.valid?
    assert subject.errors.of_kind?(:attribute, :not_reasonable_boolean)
  end

  private

  def subject
    @subject ||= build_validator_mock(
      validator: 'full_metal_body/internal/reasonable_boolean',
      options: @options
    ).new(attribute: @value)
  end
end