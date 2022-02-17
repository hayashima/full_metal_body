require "test_helper"

class FullMetalBody::DynamicWhitelistGeneratorTest < ActiveSupport::TestCase

  setup do
    @whitelist = {}
  end

  teardown do
    @subject = nil
  end

  test 'keys should registered whitelist when the value type is a string' do
    @keys = %w(article title)
    @value = 'First post'
    assert_equal({"article" => {"title" => {"type" => "string"}}}, subject)
  end

  test 'keys should registered whitelist when the value type is a number' do
    @keys = %w(article id)
    @value = 1
    assert_equal({"article" => {"id" => {"type" => "number"}}}, subject)
  end

  test 'keys should registered whitelist when the value type is a boolean' do
    @keys = %w(article draft)
    @value = true
    assert_equal({"article" => {"draft" => {"type" => "boolean"}}}, subject)
  end

  test 'keys should registered whitelist when the last key type is integer of string.' do
    @keys = %w(article comments 0)
    @value = 1
    assert_equal({
                   "article" => {
                     "comments" => {
                       "type" => "array",
                       "properties" => {
                         "type" => "number",
                       }
                     }
                   }
                 }, subject)
  end

  test 'keys should registered whitelist when the last key type is integer.' do
    @keys = ['article', 'comments', 0]
    @value = 1
    assert_equal({
                   "article" => {
                     "comments" => {
                       "type" => "array",
                       "properties" => {
                         "type" => "number",
                       }
                     }
                   }
                 }, subject)
  end

  test 'keys should registered whitelist when keys include integer of string and the last key type is string.' do
    @keys = %w(article comments 0 id)
    @value = 1
    assert_equal({
                   "article" => {
                     "comments" => {
                       "type" => "array",
                       "properties" => {
                         "id" => {
                           "type" => "number",
                         }
                       }
                     }
                   }
                 }, subject)
  end

  test 'keys should registered whitelist when keys include integer and the last key type is string.' do
    @keys = ['article', 'comments', 0, 'id']
    @value = 1
    assert_equal({
                   "article" => {
                     "comments" => {
                       "type" => "array",
                       "properties" => {
                         "id" => {
                           "type" => "number",
                         }
                       }
                     }
                   }
                 }, subject)
  end

  test 'keys should registered whitelist when keys include multiple integer of string and the last key type is string.' do
    @keys = %w(article comments 0 tags 0 id)
    @value = 1
    assert_equal({
                   "article" => {
                     "comments" => {
                       "type" => "array",
                       "properties" => {
                         "tags" => {
                           "type" => "array",
                           "properties" => {
                             "id" => {
                               "type" => "number"
                             }
                           }
                         }
                       }
                     }
                   }
                 }, subject)
  end

  test 'keys should registered whitelist when keys include multiple integer and the last key type is string.' do
    @keys = ['article', 'comments', 0, 'tags', 0, 'id']
    @value = 1
    assert_equal({
                   "article" => {
                     "comments" => {
                       "type" => "array",
                       "properties" => {
                         "tags" => {
                           "type" => "array",
                           "properties" => {
                             "id" => {
                               "type" => "number"
                             }
                           }
                         }
                       }
                     }
                   }
                 }, subject)
  end

  test 'keys should registered whitelist when keys include multiple integer of string.' do
    @keys = %w(article comments 0 0)
    @value = 1
    assert_equal({
                   "article" => {
                     "comments" => {
                       "type" => "array",
                       "properties" => {
                         "type" => "array",
                         "properties" => {
                           "type" => "number",
                         }
                       }
                     }
                   }
                 }, subject)
  end

  test 'keys should registered whitelist when keys include multiple integer.' do
    @keys = ['article', 'comments', 0, 0]
    @value = 1
    assert_equal({
                   "article" => {
                     "comments" => {
                       "type" => "array",
                       "properties" => {
                         "type" => "array",
                         "properties" => {
                           "type" => "number",
                         }
                       }
                     }
                   }
                 }, subject)
  end

  test 'keys should registered whitelist when keys are complex.' do
    @keys = %w(article comments 0 0 id)
    @value = 1
    assert_equal({
                   "article" => {
                     "comments" => {
                       "type" => "array",
                       "properties" => {
                         "type" => "array",
                         "properties" => {
                           "id" => {
                             "type" => "number",
                           }
                         }
                       }
                     }
                   }
                 }, subject)
  end

  test 'keys should registered whitelist when keys are complex2.' do
    @keys = ['article', 'comments', 0, 0, 'id']
    @value = 1
    assert_equal({
                   "article" => {
                     "comments" => {
                       "type" => "array",
                       "properties" => {
                         "type" => "array",
                         "properties" => {
                           "id" => {
                             "type" => "number",
                           }
                         }
                       }
                     }
                   }
                 }, subject)
  end

  private

  def subject
    @subject ||= FullMetalBody::DynamicWhitelistGenerator.new(@keys, @value, @whitelist).execute!
  end
end
