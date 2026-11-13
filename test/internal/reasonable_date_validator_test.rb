require "test_helper"

class FullMetalBody::Internal::ReasonableDateValidatorTest < ActiveSupport::TestCase

  teardown do
    @subject = nil
  end

  test 'it should passed when value is hyphenated and zero-filled date.' do
    @value = "2020-02-29"
    @options = nil
    assert subject.valid?
  end

  test 'it should passed when value is hyphenated date.' do
    @value = "2020-2-9"
    @options = nil
    assert subject.valid?
  end

  test 'it should passed when value is slash-separated and zero-filled date.' do
    @value = "2020/02/29"
    @options = nil
    assert subject.valid?
  end

  test 'it should passed when value is slash-separated date.' do
    @value = "2020/2/9"
    @options = nil
    assert subject.valid?
  end

  test 'it should passed when value matches the configured format exactly.' do
    @value = '2020/02/29'
    @options = { format: '%Y/%m/%d' }
    assert subject.valid?
  end

  test 'it should not passed when value does not match the configured format exactly.' do
    @value = '2020/2/29'
    @options = { format: '%Y/%m/%d' }
    assert_not subject.valid?
  end

  test 'it should not passed when value matches the format but is a non-existent date.' do
    @value = '2020/02/31'
    @options = { format: '%Y/%m/%d' }
    assert_not subject.valid?
  end

  test 'it should passed when value equals the configured minimum date.' do
    @value = '2000-01-01'
    @options = { minimum: '2000-01-01' }
    assert subject.valid?
  end

  test 'it should not passed when value is earlier than the configured minimum date.' do
    @value = '1999-12-31'
    @options = { minimum: '2000-01-01' }
    assert_not subject.valid?
  end

  test 'it should passed when value equals the configured maximum date.' do
    @value = '2099-12-31'
    @options = { maximum: '2099-12-31' }
    assert subject.valid?
  end

  test 'it should not passed when value is later than the configured maximum date.' do
    @value = '2100-01-01'
    @options = { maximum: '2099-12-31' }
    assert_not subject.valid?
  end

  test 'it should not passed when configured bounds reject Date values.' do
    @value = Date.new(1999, 12, 31)
    @options = { minimum: '2000-01-01' }
    assert_not subject.valid?
  end

  test 'it should passed when Date value is within configured bounds.' do
    @value = Date.new(2020, 1, 1)
    @options = { minimum: '2000-01-01', maximum: '2099-12-31' }
    assert subject.valid?
  end

  test 'it should passed when value is nil.' do
    @value = nil
    @options = nil
    assert subject.valid?
  end

  test 'it should passed when value is empty character.' do
    @value = ''
    @options = nil
    assert subject.valid?
  end

  test 'it should not passed when value is non-existent date.' do
    @value = '2019-02-29'
    @options = nil
    assert_not subject.valid?
    assert subject.errors.of_kind?(:attribute, :not_reasonable_date)
  end

  test 'it should not passed when value contains hyphen and slash.' do
    @value = '2019-02/09'
    @options = nil
    assert_not subject.valid?
    assert subject.errors.of_kind?(:attribute, :not_reasonable_date)
  end

  test 'it should not passed when value is date with double-digit year.' do
    @value = '19-02-09'
    @options = nil
    assert_not subject.valid?
    assert subject.errors.of_kind?(:attribute, :not_reasonable_date)
  end

  test 'it should not passed when value is string.' do
    @value = 'あいうえお'
    @options = nil
    assert_not subject.valid?
    assert subject.errors.of_kind?(:attribute, :not_reasonable_date)
  end

  test 'it should not passed when value is double digit number.' do
    @value = '20'
    @options = nil
    assert_not subject.valid?
    assert subject.errors.of_kind?(:attribute, :not_reasonable_date)
  end

  test 'it should not passed when value is triple digit number.' do
    @value = '200'
    @options = nil
    assert_not subject.valid?
    assert subject.errors.of_kind?(:attribute, :not_reasonable_date)
  end

  test 'it should not passed when value is fifth digit number.' do
    @value = '19121'
    @options = nil
    assert_not subject.valid?
    assert subject.errors.of_kind?(:attribute, :not_reasonable_date)
  end

  test 'it should not passed when value is seventh digit number.' do
    @value = '0090228'
    @options = nil
    assert_not subject.valid?
    assert subject.errors.of_kind?(:attribute, :not_reasonable_date)
  end

  test 'it should not passed when value is eighth digit number.' do
    @value = '20090228'
    @options = nil
    assert_not subject.valid?
    assert subject.errors.of_kind?(:attribute, :not_reasonable_date)
  end

  test 'it should not passed when value contains initial of japanese era.' do
    @value = 'S64.01.01'
    @options = nil
    assert_not subject.valid?
    assert subject.errors.of_kind?(:attribute, :not_reasonable_date)
  end

  test 'it should not passed when value contains japanese era.' do
    @value = '昭和64.01.01'
    @options = nil
    assert_not subject.valid?
    assert subject.errors.of_kind?(:attribute, :not_reasonable_date)
  end

  private

  def subject
    @subject ||= build_validator_mock(
      validator: 'full_metal_body/internal/reasonable_date',
      options: @options
    ).new(attribute: @value)
  end
end
