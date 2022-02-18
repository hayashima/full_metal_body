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
  test 'it should be succeeded when value type is integer' do
    @keys = ['key']
    @value = '12345'
    @whitelist = {
      'key' => {
        'type' => 'number',
      },
    }
    it_is_valid_with_whitelist
  end

  test 'it should be succeeded when value type is float' do
    @keys = ['key']
    @value = '12345.67'
    @whitelist = {
      'key' => {
        'type' => 'number',
      },
    }
    it_is_valid_with_whitelist
  end

  test 'it should be succeeded when value is empty' do
    @keys = ['key']
    @value = ''
    @whitelist = {
      'key' => {
        'type' => 'number',
      },
    }
    it_is_valid_with_whitelist
  end

  test 'it should be succeeded when value is nil' do
    @keys = ['key']
    @value = nil
    @whitelist = {
      'key' => {
        'type' => 'number',
      },
    }
    it_is_valid_with_whitelist
  end

  test 'it should be succeeded when value is greater than 4 and even' do
    @keys = ['key']
    @value = '6'
    @whitelist = {
      'key' => {
        'type' => 'number',
        'options' => {
          'even' => true,
          'greater_than' => 4
        },
      },
    }
    it_is_valid_with_whitelist
  end

  test 'it should be failed when value is not a number' do
    @keys = ['key']
    @value = '0x192'
    @whitelist = {
      'key' => {
        'type' => 'number',
      },
    }
    it_is_invalid_with_whitelist
  end

  test 'it should be failed when value is 4' do
    @keys = ['key']
    @value = '4'
    @whitelist = {
      'key' => {
        'type' => 'number',
        'options' => {
          'even' => true,
          'greater_than' => 4
        },
      },
    }
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

  def set_dynamic_whitelist
    @whitelist = FullMetalBody::DynamicWhitelistGenerator.new(@keys, @value).execute!
  end

end
