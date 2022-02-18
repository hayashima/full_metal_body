require "test_helper"

class FullMetalBody::WhitelistWriterTest < ActiveSupport::TestCase

  setup do
    FileUtils.rm_rf(Rails.root.join('tmp', "test#{ENV.fetch('TEST_ENV_NUMBER', '')}", 'whitelist'))
    @controller_path = 'articles'
    @action_name = 'create'
    @blocked_keys = [
      ['foo'],
      ['bar'],
      ['baz'],
    ]
  end

  test 'it should create a whitelist file.' do
    assert_changes -> { File.exist?(subject.save_path) }, from: false, to: true do
      subject.write!(@blocked_keys)
    end
    assert_yaml_correct do
      {
        'articles' => {
          'create' => {
            'bar' => {
              'type' => 'string',
            },
            'baz' => {
              'type' => 'string',
            },
            'foo' => {
              'type' => 'string',
            },
          },
        },
      }
    end
  end

  test 'it should be correct when blocked_keys are complex.' do
    @blocked_keys = [
      ['article', 'title'],
      ['article', 'content'],
      ['article', 'tags', '0'],
      ['article', 'tags', '1'],
      ['article', 'tags', '2'],
    ]
    subject.write!(@blocked_keys)
    assert_yaml_correct do
      {
        'articles' => {
          'create' => {
            'article' => {
              'content' => {
                'type' => 'string',
              },
              'tags' => {
                'properties' => {
                  'type' => 'string',
                },
                'type' => 'array',
              },
              'title' => {
                'type' => 'string',
              },
            },
          },
        },
      }
    end
  end

  test 'it should be merge when the whitelist file is already exists.' do
    current_whitelist = {
      'articles' => {
        'index' => {
          'p' => {
            'type' => 'number'
          }
        }
      }
    }
    FileUtils.mkdir_p(File.dirname(subject.save_path), mode: 0o777)
    File.open(subject.save_path, 'w') do |file|
      YAML.dump(current_whitelist, file)
    end
    subject.write!(@blocked_keys)
    assert_yaml_correct do
      {
        'articles' => {
          'create' => {
            'bar' => {
              'type' => 'string',
            },
            'baz' => {
              'type' => 'string',
            },
            'foo' => {
              'type' => 'string',
            },
          },
          'index' => {
            'p' => {
              'type' => 'number',
            },
          },
        },
      }
    end
  end

  private

  def subject
    @subject ||= FullMetalBody::WhitelistWriter.new(@controller_path, @action_name)
  end

  def assert_yaml_correct(&block)
    whitelist = YAML.load_file(subject.save_path)
    assert_equal(block.call, whitelist)
  end

end
