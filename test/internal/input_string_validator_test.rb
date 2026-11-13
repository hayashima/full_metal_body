require "test_helper"

class FullMetalBody::Internal::InputStringValidatorTest < ActiveSupport::TestCase

  setup do
    @value = "今日はいいお天気ですね☀!　㈱\"#$%&'()=~|-^\\[]+*<>,.?_{}; :🐶🐈𡸴𣗄"
  end

  teardown do
    @subject = nil
  end

  test 'it should passed when options is nil' do
    @options = nil
    assert subject.valid?
  end

  test 'it should passed when value length is 1024.' do
    @value = "あ" * 1024
    @options = nil
    assert subject.valid?
  end

  test 'it should not passed when value length is 1025.' do
    @value = "あ" * 1025
    @options = nil
    assert_not subject.valid?
  end

  test 'it should passed when value.length is not exceeded max_length' do
    @value = "a" * 50
    @options = { max_length: 50 }
    assert subject.valid?
  end

  test 'it should not passed when value.length is exceeded max_length' do
    @value = "a" * 51
    @options = { max_length: 50 }
    assert_not subject.valid?
  end

  test 'it should pass when value matches pattern' do
    @value = 'AB1234'
    @options = { pattern: '[A-Z]{2}[0-9]{4}' }
    assert subject.valid?
  end

  test 'it should pass when value matches an extended pattern with a trailing comment' do
    @value = 'AB1234'
    @options = { pattern: '(?x)[A-Z]{2}[0-9]{4} # identifier' }
    assert subject.valid?
  end

  test 'it should fail when value does not match the entire pattern' do
    @value = 'prefix-AB1234-suffix'
    @options = { pattern: '[A-Z]{2}[0-9]{4}' }
    assert_not subject.valid?
    assert subject.errors.of_kind?(:attribute, :invalid_format)
  end

  test 'it should fail when a line break interrupts the pattern' do
    @value = "AB\n1234"
    @options = { pattern: '[A-Z]{2}[0-9]{4}' }
    assert_not subject.valid?
    assert subject.errors.of_kind?(:attribute, :invalid_format)
  end

  test 'it should raise when pattern is not a string' do
    @options = { pattern: 123 }
    error = assert_raises(ArgumentError) { subject }
    assert_equal ':pattern must be a String', error.message
  end

  test 'it should raise when pattern is an invalid regular expression' do
    @options = { pattern: '[' }
    error = assert_raises(ArgumentError) { subject }
    assert_match(/:pattern must be a valid regular expression/, error.message)
  end

  test 'it should passed when value contains line feeds or horizontal tabs.' do
    @value = "あい\r\nうえ\rお\nかき\tくけこ"
    @options = nil
    assert subject.valid?
  end

  test 'it should not passed when value type is not string.' do
    @value = 123
    @options = nil
    assert_not subject.valid?
    assert subject.errors.of_kind?(:attribute, :wrong_type)
  end

  test 'it should not passed when encoding is not utf-8.' do
    @value = "あいうえお".encode('EUC-JP', 'UTF-8')
    @options = nil
    assert_not subject.valid?
    assert subject.errors.of_kind?(:attribute, :wrong_encoding)
  end

  test 'it should not passed when value contains control characters other than line feeds and horizontal tabs' do
    @value = "あいう\bえお\nかき\vくけこ"
    @options = nil
    assert_not subject.valid?
    assert subject.errors.of_kind?(:attribute, :include_cntrl)
  end

  private

  def subject
    @subject ||= build_validator_mock(
      validator: 'full_metal_body/internal/input_string',
      options: @options
    ).new(attribute: @value)
  end
end
