require "test_helper"

class FullMetalBody::Internal::InputFileValidatorTest < ActiveSupport::TestCase

  setup do
    @value = ActionDispatch::Http::UploadedFile.new(
      filename: 'mandrill.png',
      type: 'image/png',
      tempfile: file_fixture('images/mandrill.png').read
    )
  end

  teardown do
    @subject = nil
  end

  test 'it should pass when option of content_type is string.' do
    @options = { content_type: 'image/png', file_size: 1.megabyte }
    assert subject.valid?
  end

  test 'it should pass when option of content_type is array.' do
    @options = { content_type: %w(image/png image/jpg), file_size: 1.megabyte }
    assert subject.valid?
  end

  test 'it should pass when options is nil.' do
    @options = nil
    assert subject.valid?
  end

  test 'it should pass when options and value are nil.' do
    @options = nil
    @value = nil
    assert subject.valid?
  end

  test 'it should not pass when value is not file.' do
    @options = { content_type: 'image/png', file_size: 1.megabyte }
    @value = 'abc'
    assert_not subject.valid?
    assert subject.errors.of_kind?(:attribute, :file_wrong_type)
  end

  test 'it should not pass when content_type is wrong.' do
    @options = { content_type: 'application/pdf', file_size: 1.megabyte }
    assert_not subject.valid?
    assert subject.errors.of_kind?(:attribute, :invalid_content_type)
  end

  test 'it should not pass when file_size is exceeded.' do
    @options = { content_type: 'image/png', file_size: 100.kilobytes }
    assert_not subject.valid?
    assert subject.errors.of_kind?(:attribute, :too_large_size)
  end

  test 'it should not pass when options is nil and file_size is exceeded.' do
    @options = nil 
    @value = ActionDispatch::Http::UploadedFile.new(
      filename: 'mandrill.pdf',
      type: 'application/pdf',
      tempfile: StringIO.new('a' * 101.megabytes),
    )
    assert_not subject.valid?
    assert subject.errors.of_kind?(:attribute, :too_large_size)
  end

  private

  def subject
    @subject ||= build_validator_mock(
      validator: 'full_metal_body/internal/input_file',
      options: @options
    ).new(attribute: @value)
  end
end
