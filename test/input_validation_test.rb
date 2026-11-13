require "test_helper"

class FullMetalBody::InputValidationTest < ActiveSupport::TestCase
  teardown do
    @subject = nil
  end

  #
  # String: start
  #
  test 'it should be succeeded when keys are correct.' do
    @keys = ['foo', 'bar', '1', 'key']
    @value = 'value'
    @whitelist = nil
    it_is_valid_without_whitelist
  end

  test 'it should be failed when keys are incorrect.' do
    @keys = ["foo\b", 'bar', '1', 'key']
    @value = 'value'
    @whitelist = nil
    it_is_invalid_without_whitelist
  end

  test 'it should be succeeded when whitelist is valid.' do
    @keys = ['key']
    @value = 'value'
    @whitelist = { 'key' => { 'type' => 'string' } }
    it_is_valid_with_whitelist
  end

  test 'it should be failed when value include invalid string.' do
    @keys = ['key']
    @value = "val\bue"
    @whitelist = { 'key' => { 'type' => 'string' } }
    it_is_invalid_with_whitelist
  end

  test 'it should be succeeded when whitelist with options is valid.' do
    @keys = ['key']
    @value = 'a' * 5
    @whitelist = {
      'key' => {
        'type' => 'string',
        'options' => {
          'max_length' => 5
        }
      }
    }
    it_is_valid_with_whitelist
  end

  test 'it should be failed when value.length is too long.' do
    @keys = ['key']
    @value = 'a' * 6
    @whitelist = {
      'key' => {
        'type' => 'string',
        'options' => {
          'max_length' => 5
        }
      }
    }
    it_is_invalid_with_whitelist
  end

  test 'it should be succeeded when string pattern matches.' do
    @keys = ['key']
    @value = 'AB1234'
    @whitelist = {
      'key' => {
        'type' => 'string',
        'options' => {
          'pattern' => '[A-Z]{2}[0-9]{4}'
        }
      }
    }
    it_is_valid_with_whitelist
  end

  test 'it should be failed when string does not fully match pattern.' do
    @keys = ['key']
    @value = 'prefix-AB1234-suffix'
    @whitelist = {
      'key' => {
        'type' => 'string',
        'options' => {
          'pattern' => '[A-Z]{2}[0-9]{4}'
        }
      }
    }
    it_is_invalid_with_whitelist
  end

  test 'it should be succeeded when keys are simple array.' do
    @keys = %w(key 1)
    @value = 'value'
    @whitelist = {
      'key' => {
        'type' => 'array',
        'properties' => {
          'type' => 'string',
        },
      },
    }
    it_is_valid_with_whitelist
  end

  test 'it should be succeeded when keys are nested array.' do
    @keys = %w[key 0 0]
    @value = 'value'
    @whitelist = {
      'key' => {
        'type' => 'array',
        'properties' => {
          'type' => 'array',
          'properties' => {
            'type' => 'string',
          },
        },
      },
    }
    it_is_valid_with_whitelist
  end

  test 'it should be succeeded when keys are nested array and an object.' do
    @keys = %w[key 1 child_key 2]
    @value = 'value'
    @whitelist = {
      'key' => {
        'type' => 'array',
        'properties' => {
          'child_key' => {
            'type' => 'array',
            'properties' => {
              'type' => 'string',
            },
          },
        },
      },
    }
    it_is_valid_with_whitelist
  end

  test '複雑なホワイトリストの場合でキーと一致しない場合' do
    @keys = %w[key 1 2 3]
    @value = 'value'
    @whitelist = {
      'key' => {
        'type' => 'array',
        'properties' => {
          'type' => 'array',
          'properties' => {
            'type' => 'array',
            'properties' => {
              'true_key' => {
                'type' => 'string',
              },
            },
          },
        },
      },
    }
    it_is_valid_without_whitelist
  end
  #
  # String: end
  #

  #
  # Number: start
  #
  test 'accepts integer strings as numbers' do
    set_number_validation('12345')
    it_is_valid_with_whitelist
  end

  test 'accepts decimal strings as numbers' do
    set_number_validation('12345.67')
    it_is_valid_with_whitelist
  end

  test 'allows empty strings by default' do
    set_number_validation('')
    it_is_valid_with_whitelist
  end

  test 'allows nil values by default' do
    set_number_validation(nil)
    it_is_valid_with_whitelist
  end

  test 'accepts values above the strict lower bound' do
    set_number_validation('6', 'greater_than' => 4)
    it_is_valid_with_whitelist
  end

  test 'accepts the inclusive lower bound' do
    set_number_validation('1', 'greater_than_or_equal_to' => 1)
    it_is_valid_with_whitelist
  end

  test 'rejects values below the inclusive lower bound' do
    set_number_validation('0', 'greater_than_or_equal_to' => 1)
    it_is_invalid_with_whitelist
  end

  test 'accepts the inclusive upper bound' do
    set_number_validation('100', 'less_than_or_equal_to' => 100)
    it_is_valid_with_whitelist
  end

  test 'rejects values above the inclusive upper bound' do
    set_number_validation('101', 'less_than_or_equal_to' => 100)
    it_is_invalid_with_whitelist
  end

  test 'rejects decimal strings when only_integer is enabled' do
    set_number_validation('1.5', 'only_integer' => true)
    it_is_invalid_with_whitelist
  end

  test 'rejects strings that are not numbers' do
    set_number_validation('0x192')
    it_is_invalid_with_whitelist
  end

  test 'rejects a value equal to the strict lower bound' do
    set_number_validation('4', 'greater_than' => 4)
    it_is_invalid_with_whitelist
  end

  test 'accepts values equal to the equal_to constraint' do
    set_number_validation('5', 'equal_to' => 5)
    it_is_valid_with_whitelist
  end

  test 'rejects values unequal to the equal_to constraint' do
    set_number_validation('4', 'equal_to' => 5)
    it_is_invalid_with_whitelist
  end

  test 'accepts values below the strict upper bound' do
    set_number_validation('5', 'less_than' => 6)
    it_is_valid_with_whitelist
  end

  test 'rejects a value equal to the strict upper bound' do
    set_number_validation('6', 'less_than' => 6)
    it_is_invalid_with_whitelist
  end

  test 'accepts values different from the other_than constraint' do
    set_number_validation('5', 'other_than' => 4)
    it_is_valid_with_whitelist
  end

  test 'rejects values equal to the other_than constraint' do
    set_number_validation('4', 'other_than' => 4)
    it_is_invalid_with_whitelist
  end

  test 'accepts even values when even is required' do
    set_number_validation('6', 'even' => true)
    it_is_valid_with_whitelist
  end

  test 'rejects odd values when even is required' do
    set_number_validation('5', 'even' => true)
    it_is_invalid_with_whitelist
  end

  test 'accepts odd values when odd is required' do
    set_number_validation('5', 'odd' => true)
    it_is_valid_with_whitelist
  end

  test 'rejects even values when odd is required' do
    set_number_validation('6', 'odd' => true)
    it_is_invalid_with_whitelist
  end

  test 'accepts Numeric instances as number values' do
    set_number_validation(123)
    it_is_valid_with_whitelist
  end

  test 'accepts values within the numericality range' do
    skip_unless_active_model_version('7.0')

    set_number_validation('50', 'in' => 1..100)
    it_is_valid_with_whitelist
  end

  test 'rejects values outside the numericality range' do
    skip_unless_active_model_version('7.0')

    set_number_validation('101', 'in' => 1..100)
    it_is_invalid_with_whitelist
  end

  test 'accepts Numeric instances when only_numeric is enabled' do
    skip_unless_active_model_version('7.1')

    set_number_validation(123, 'only_numeric' => true)
    it_is_valid_with_whitelist
  end

  test 'rejects String values when only_numeric is enabled' do
    skip_unless_active_model_version('7.1')

    set_number_validation('123', 'only_numeric' => true)
    it_is_invalid_with_whitelist
  end
  #
  # Number: end
  #

  #
  # Date: start
  #
  test 'it should be succeeded when the format of value is date' do
    @keys = ['key']
    @value = '1993/11/03'
    @whitelist = {
      'key' => {
        'type' => 'date',
      },
    }
    it_is_valid_with_whitelist
  end

  test 'it should be failed when the value is invalid date' do
    @keys = ['key']
    @value = '1993/02/29'
    @whitelist = {
      'key' => {
        'type' => 'date',
      },
    }
    it_is_invalid_with_whitelist
  end

  test 'it should be succeeded when date options match the value' do
    set_date_validation('2020-02-29', 'format' => '%Y-%m-%d', 'minimum' => '2000-01-01', 'maximum' => '2099-12-31')
    it_is_valid_with_whitelist
  end

  test 'it should be failed when date options reject the value' do
    set_date_validation('1999-12-31', 'format' => '%Y-%m-%d', 'minimum' => '2000-01-01')
    it_is_invalid_with_whitelist
  end

  test 'it should be failed when value exceeds the configured maximum date' do
    set_date_validation('2100-01-01', 'format' => '%Y-%m-%d', 'maximum' => '2099-12-31')
    it_is_invalid_with_whitelist
  end
  #
  # Date: end
  #

  #
  # Boolean: start
  #
  test 'it should be succeeded when the format of value is boolean' do
    @keys = ['key']
    @whitelist = {
      'key' => {
        'type' => 'boolean',
      },
    }
    ['true', '1', true, false].each do |bool|
      @value = bool
      it_is_valid_with_whitelist
      @subject = nil
    end
  end

  test 'it should be failed when the format of value is invalid' do
    @keys = ['key']
    @whitelist = {
      'key' => {
        'type' => 'boolean',
      },
    }
    ["value", 1, nil, ""].each do |bool|
      @value = bool
      it_is_invalid_with_whitelist
      @subject = nil
    end
  end

  test 'it should be succeeded when the value is empty and options allow blank' do
    @keys = ['key']
    @whitelist = {
      'key' => {
        'type' => 'boolean',
        'options' => {
          'allow_blank' => true
        }
      },
    }
    [nil, ""].each do |bool|
      @value = bool
      it_is_valid_with_whitelist
      @subject = nil
    end
  end

  test 'it should be succeeded when configured boolean values are used' do
    @keys = ['key']
    @whitelist = {
      'key' => {
        'type' => 'boolean',
        'options' => {
          'true_values' => ['yes'],
          'false_values' => ['no'],
        },
      },
    }
    ['yes', 'no', true, false].each do |bool|
      @value = bool
      it_is_valid_with_whitelist
      @subject = nil
    end
  end

  test 'it should be failed when boolean value is not in the configured values' do
    @keys = ['key']
    @value = 'true'
    @whitelist = {
      'key' => {
        'type' => 'boolean',
        'options' => {
          'true_values' => ['yes'],
          'false_values' => ['no'],
        },
      },
    }
    it_is_invalid_with_whitelist
  end
  #
  # Boolean: end
  #

  #
  # File: start
  #
  test 'it should be succeeded when value is an image.' do
    @keys = ['key']
    @value = upload_image
    @whitelist = {
      'key' => {
        'type' => 'file',
        'options' => {
          'content_type' => 'image/png',
          'file_size' => 1.megabyte,
        },
      },
    }
    it_is_valid_with_whitelist
  end

  test 'it should be succeeded when whitelist is undefined.' do
    @keys = ['key']
    @value = upload_image
    @whitelist = nil
    it_is_valid_without_whitelist
  end

  test 'it should be failed when a file size is too big.' do
    @keys = ['key']
    @value = upload_text(file_size: 101.megabytes)
    @whitelist = nil
    it_is_invalid_without_whitelist
  end

  test 'it should be succeeded when file extension matches configured options.' do
    @keys = ['key']
    @value = upload_image
    @whitelist = {
      'key' => {
        'type' => 'file',
        'options' => {
          'content_type' => 'image/png',
          'file_size' => 1.megabyte,
          'allowed_extensions' => ['.png'],
        },
      },
    }
    it_is_valid_with_whitelist
  end
  #
  # File: end
  #

  #
  # DynamicWhitelistGenerator: start
  #
  test 'it should be succeeded when integer value is valid in whitelist generated by DynamicWhitelistGenerator' do
    @keys = ['key']
    @value = 1
    set_dynamic_whitelist
    it_is_valid_with_whitelist
  end

  test 'it should be failed when control characters value is invalid in whitelist generated by DynamicWhitelistGenerator' do
    @keys = ['key']
    @value = "va\bue"
    set_dynamic_whitelist
    it_is_invalid_with_whitelist
  end

  test 'it should be succeeded when string value is valid in whitelist generated by DynamicWhitelistGenerator' do
    @keys = ['key']
    @value = "a" * 1024
    set_dynamic_whitelist
    it_is_valid_with_whitelist
  end

  test 'it should be failed when too long string value is valid in whitelist generated by DynamicWhitelistGenerator' do
    @keys = ['key']
    @value = "a" * 1025
    set_dynamic_whitelist
    it_is_invalid_with_whitelist
  end

  test 'it should be succeeded when date value is valid in whitelist generated by DynamicWhitelistGenerator' do
    @keys = ['key']
    @value = Date.new(2022, 1, 1)
    set_dynamic_whitelist
    it_is_valid_with_whitelist
  end

  test 'it should be succeeded when boolean value is valid in whitelist generated by DynamicWhitelistGenerator' do
    @keys = ['key']
    @value = true
    set_dynamic_whitelist
    it_is_valid_with_whitelist
  end

  test 'keys includes array' do
    @keys = ['article', 'comments', 0]
    @value = 1
    set_dynamic_whitelist
    it_is_valid_with_whitelist
  end

  test 'keys include array and object attribute' do
    @keys = ['article', 'comments', 0, 'id']
    @value = 1
    set_dynamic_whitelist
    it_is_valid_with_whitelist
  end

  test 'keys include nested array' do
    @keys = ['article', 'comments', 0, 0]
    @value = 1
    set_dynamic_whitelist
    it_is_valid_with_whitelist
  end

  test 'keys include nested array and object attribute' do
    @keys = ['article', 'comments', 0, 0, 'id']
    @value = 1
    set_dynamic_whitelist
    it_is_valid_with_whitelist
  end

  test 'keys include nested array and nested object attribute' do
    @keys = ['article', 'comments', 0, 'tags', 0, 'name']
    @value = 1
    set_dynamic_whitelist
    it_is_valid_with_whitelist
  end
  #
  # DynamicWhitelistGenerator whitelist: end
  #

  private

  def subject
    @subject ||= FullMetalBody::InputValidation.new(@keys, @value, @whitelist)
  end

  def it_is_valid_with_whitelist
    assert subject.valid?
    assert_not_nil(subject.key_type)
  end

  def it_is_valid_without_whitelist
    assert subject.valid?
    assert_nil(subject.key_type)
  end

  def it_is_invalid_with_whitelist
    assert_not subject.valid?
    assert_not_nil(subject.key_type)
  end

  def it_is_invalid_without_whitelist
    assert_not subject.valid?
    assert_nil(subject.key_type)
  end

  def set_number_validation(value, options = nil)
    @keys = ['key']
    @value = value
    definition = { 'type' => 'number' }
    definition['options'] = options if options
    @whitelist = { 'key' => definition }
    @subject = nil
  end

  def set_date_validation(value, options = nil)
    @keys = ['key']
    @value = value
    definition = { 'type' => 'date' }
    definition['options'] = options if options
    @whitelist = { 'key' => definition }
    @subject = nil
  end

  def skip_unless_active_model_version(minimum_version)
    current_version = Gem::Version.new(ActiveModel::VERSION::STRING)
    required_version = Gem::Version.new(minimum_version)
    skip "requires ActiveModel #{minimum_version}+" if current_version < required_version
  end

  def set_dynamic_whitelist
    @whitelist = FullMetalBody::DynamicWhitelistGenerator.new(@keys, @value).execute!
  end

end
