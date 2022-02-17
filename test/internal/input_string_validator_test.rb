require "test_helper"

class FullMetalBody::Internal::InputStringValidatorTest < ActiveSupport::TestCase

  setup do
    @value = "今日はいいお天気ですね☀!　㈱\"#$%&'()=~|-^\\[]+*<>,.?_{}; :🐶🐈𡸴𣗄"
  end

  teardown do
    @mock = nil
  end

  test 'it should passed when options is nil' do
    @options = nil
    assert mock.valid?
  end

  test 'it should passed when value length is 1024.' do
    @value = "あ" * 1024
    @options = nil
    assert mock.valid?
  end

  test 'it should not passed when value length is 1025.' do
    @value = "あ" * 1025
    @options = nil
    assert_not mock.valid?
  end

  test 'it should passed when value.length is not exceeded max_length' do
    @value = "a" * 50
    @options = { max_length: 50 }
    assert mock.valid?
  end

  test 'it should not passed when value.length is exceeded max_length' do
    @value = "a" * 51
    @options = { max_length: 50 }
    assert_not mock.valid?
  end

  test 'it should passed when value contains line feeds or horizontal tabs.' do
    @value = "あい\r\nうえ\rお\nかき\tくけこ"
    @options = nil
    assert mock.valid?
  end

  test 'it should not passed when value type is not string.' do
    @value = 123
    @options = nil
    assert_not mock.valid?
    assert mock.errors.of_kind?(:attribute, :wrong_type)
  end

  test 'it should not passed when encoding is not utf-8.' do
    @value = "あいうえお".encode('EUC-JP', 'UTF-8')
    @options = nil
    assert_not mock.valid?
    assert mock.errors.of_kind?(:attribute, :wrong_encoding)
  end

  test 'it should not passed when value contains control characters other than line feeds and horizontal tabs' do
    @value = "あいう\bえお\nかき\vくけこ"
    @options = nil
    assert_not mock.valid?
    assert mock.errors.of_kind?(:attribute, :include_cntrl)
  end

  private

  def mock
    @mock ||= build_validator_mock(
      validator: 'full_metal_body/internal/input_string',
      options: @options
    ).new(attribute: @value)
  end
end
