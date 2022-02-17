require "test_helper"

class FullMetalBody::Internal::ReasonableDateValidatorTest < ActiveSupport::TestCase

  teardown do
    @mock = nil
  end

  test 'it should passed when value is hyphenated and zero-filled date.' do
    @value = "2020-02-29"
    @options = nil
    assert mock.valid?
  end

  test 'it should passed when value is hyphenated date.' do
    @value = "2020-2-9"
    @options = nil
    assert mock.valid?
  end

  test 'it should passed when value is slash-separated and zero-filled date.' do
    @value = "2020/02/29"
    @options = nil
    assert mock.valid?
  end

  test 'it should passed when value is slash-separated date.' do
    @value = "2020/2/9"
    @options = nil
    assert mock.valid?
  end

  test 'it should passed when value is nil.' do
    @value = nil
    @options = nil
    assert mock.valid?
  end

  test 'it should passed when value is empty character.' do
    @value = ''
    @options = nil
    assert mock.valid?
  end

  test 'it should not passed when value is non-existent date.' do
    @value = '2019-02-29'
    @options = nil
    assert_not mock.valid?
    assert mock.errors.of_kind?(:attribute, :not_reasonable_date)
  end

  test 'it should not passed when value contains hyphen and slash.' do
    @value = '2019-02/09'
    @options = nil
    assert_not mock.valid?
    assert mock.errors.of_kind?(:attribute, :not_reasonable_date)
  end

  test 'it should not passed when value is date with double-digit year.' do
    @value = '19-02-09'
    @options = nil
    assert_not mock.valid?
    assert mock.errors.of_kind?(:attribute, :not_reasonable_date)
  end

  test 'it should not passed when value is string' do
    @value = 'あいうえお'
    @options = nil
    assert_not mock.valid?
    assert mock.errors.of_kind?(:attribute, :not_reasonable_date)
  end

  test 'it should not passed when value is double digit number.' do
    @value = '20'
    @options = nil
    assert_not mock.valid?
    assert mock.errors.of_kind?(:attribute, :not_reasonable_date)
  end

  test 'it should not passed when value is triple digit number.' do
    @value = '200'
    @options = nil
    assert_not mock.valid?
    assert mock.errors.of_kind?(:attribute, :not_reasonable_date)
  end

  test 'it should not passed when value is fifth digit number.' do
    @value = '19121'
    @options = nil
    assert_not mock.valid?
    assert mock.errors.of_kind?(:attribute, :not_reasonable_date)
  end

  test 'it should not passed when value is seventh digit number.' do
    @value = '0090228'
    @options = nil
    assert_not mock.valid?
    assert mock.errors.of_kind?(:attribute, :not_reasonable_date)
  end

  test 'it should not passed when value is eighth digit number.' do
    @value = '20090228'
    @options = nil
    assert_not mock.valid?
    assert mock.errors.of_kind?(:attribute, :not_reasonable_date)
  end

  test 'it should not passed when value contains initial of japanese era.' do
    @value = 'S64.01.01'
    @options = nil
    assert_not mock.valid?
    assert mock.errors.of_kind?(:attribute, :not_reasonable_date)
  end

  test 'it should not passed when value is contains japanese era.' do
    @value = '昭和64.01.01'
    @options = nil
    assert_not mock.valid?
    assert mock.errors.of_kind?(:attribute, :not_reasonable_date)
  end

  private

  def mock
    @mock ||= build_validator_mock(
      validator: 'full_metal_body/internal/reasonable_date',
      options: @options
    ).new(attribute: @value)
  end
end
