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

  test 'it should pass when file extension matches regardless of case.' do
    @value = ActionDispatch::Http::UploadedFile.new(
      filename: 'mandrill.PNG',
      type: 'image/png',
      tempfile: StringIO.new(file_fixture('images/mandrill.png').read)
    )
    @options = { allowed_extensions: ['.png'] }
    assert subject.valid?
  end

  test 'it should pass when a compound file extension matches regardless of case.' do
    @value = ActionDispatch::Http::UploadedFile.new(
      filename: 'backup.TAR.GZ',
      type: 'application/gzip',
      tempfile: StringIO.new('archive')
    )
    @options = { allowed_extensions: ['.tar.gz'] }
    assert subject.valid?
  end

  test 'it should not pass when only the last part of a compound extension matches.' do
    @value = ActionDispatch::Http::UploadedFile.new(
      filename: 'backup.gz',
      type: 'application/gzip',
      tempfile: StringIO.new('archive')
    )
    @options = { allowed_extensions: ['.tar.gz'] }
    assert_not subject.valid?
    assert subject.errors.of_kind?(:attribute, :invalid_extension)
  end

  test 'it should not pass when file extension is not allowed.' do
    @options = { allowed_extensions: ['.jpg'] }
    assert_not subject.valid?
    assert subject.errors.of_kind?(:attribute, :invalid_extension)
  end

  test 'it should reject a NUL-containing filename when extensions are restricted.' do
    @value = ActionDispatch::Http::UploadedFile.new(
      filename: "mandrill\0.png",
      type: 'image/png',
      tempfile: StringIO.new(file_fixture('images/mandrill.png').read)
    )
    @options = { allowed_extensions: ['.png'] }

    assert_not subject.valid?
    assert subject.errors.of_kind?(:attribute, :invalid_extension)
  end

  test 'it should raise when allowed_extensions is not an array of extensions.' do
    @options = { allowed_extensions: ['png'] }
    error = assert_raises(ArgumentError) { subject }
    assert_equal ':allowed_extensions must be an Array of extensions', error.message
  end

  test 'it should raise when allowed_extensions is false.' do
    @options = { allowed_extensions: false }
    error = assert_raises(ArgumentError) { subject }
    assert_equal ':allowed_extensions must be an Array of extensions', error.message
  end

  test 'it should pass when allowed_extensions is nil.' do
    @options = { allowed_extensions: nil }
    assert subject.valid?
  end

  test 'it should reject all files when allowed_extensions is empty.' do
    @options = { allowed_extensions: [] }
    assert_not subject.valid?
    assert subject.errors.of_kind?(:attribute, :invalid_extension)
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
    @value = upload_text(file_size: 101.megabytes)
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
