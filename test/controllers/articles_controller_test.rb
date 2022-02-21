require "test_helper"

class ArticlesControllerTest < ActionDispatch::IntegrationTest
  include StubWhitelist

  setup do
    @article = articles(:one)
  end

  test "should get index" do
    assert_no_difference -> { FullMetalBody::BlockedAction.count } do
      get articles_url
      assert_response :success
    end
  end

  test "should get index with 3 parameters" do
    get articles_url, params: {
      foo: 'foo',
      bar: 'bar',
      baz: 'baz',
    }
    assert_response :success
    blocked_action = FullMetalBody::BlockedAction.eager_load(:blocked_keys).last
    assert_equal 'articles', blocked_action.controller
    assert_equal 'index', blocked_action.action
    assert_equal [["bar"], ["baz"], ["foo"]].sort, blocked_action.blocked_keys.pluck(:blocked_key).sort
  end

  test "should not get index with 4 parameters" do
    get articles_url, params: {
      foo: 'foo',
      bar: 'bar',
      baz: 'baz',
      hoge: 'hoge',
    }
    assert_response :bad_request
    blocked_action = FullMetalBody::BlockedAction.eager_load(:blocked_keys).last
    assert_equal 'articles', blocked_action.controller
    assert_equal 'index', blocked_action.action
    assert_equal [["bar"], ["baz"], ["foo"], ["hoge"]].sort, blocked_action.blocked_keys.pluck(:blocked_key).sort
  end

  test "should get index with 4 parameters when whitelist count check is disabled." do
    ENV['USE_WHITELIST_COUNT_CHECK'] = '0'
    get articles_url, params: {
      foo: 'foo',
      bar: 'bar',
      baz: 'baz',
      hoge: 'hoge',
    }
    assert_response :success
    blocked_action = FullMetalBody::BlockedAction.eager_load(:blocked_keys).last
    assert_equal 'articles', blocked_action.controller
    assert_equal 'index', blocked_action.action
    assert_equal [["bar"], ["baz"], ["foo"], ["hoge"]].sort, blocked_action.blocked_keys.pluck(:blocked_key).sort
    ENV['USE_WHITELIST_COUNT_CHECK'] = nil
  end

  test "should get index with 4 parameters when whitelist already defined." do
    whitelist = {
      'foo' => {
        'type' => 'string',
      },
      'bar' => {
        'type' => 'string',
      },
      'baz' => {
        'type' => 'string',
      },
      'hoge' => {
        'type' => 'string',
      },
    }
    stub_whitelist(ArticlesController, whitelist) do
      assert_no_difference -> { FullMetalBody::BlockedAction.count } do
        get articles_url, params: {
          foo: 'foo',
          bar: 'bar',
          baz: 'baz',
          hoge: 'hoge',
        }
      end
    end
    assert_response :success
  end

  test "should get new" do
    get new_article_url
    assert_response :success
  end

  test "should create article with tags and images" do
    tag1 = tags(:one)
    tag2 = tags(:two)
    stub_whitelist(ArticlesController, article_whitelist) do
      assert_difference -> { Article.count } => 1,
                        -> { FullMetalBody::BlockedKey.count } => 0,
                        -> { ArticleTag.count } => 2 do
        post articles_url, params: {
          article: {
            content: @article.content,
            title: @article.title,
            article_tags_attributes: [
              { tag_id: tag1.id },
              { tag_id: tag2.id },
            ],
            images: [fixture_file_upload('images/mandrill.png', 'image/png')]
          }
        }
      end
    end

    assert_redirected_to article_url(Article.last)
  end

  test "should show article" do
    assert_difference -> { FullMetalBody::BlockedAction.count } => 1 do
      get article_url(@article)
      assert_response :success
    end
  end

  test "should get edit" do
    assert_difference "FullMetalBody::BlockedAction.count" do
      get edit_article_url(@article)
    end
    assert_response :success
  end

  test "should update article" do
    stub_whitelist(ArticlesController, article_whitelist.bury(%w[id type], 'number')) do
      assert_no_difference [-> { Article.count }, -> { FullMetalBody::BlockedKey.count }] do
        patch article_url(@article),
             params: {
               article: {
                 content: @article.content,
                 title: @article.title,
                 images: [fixture_file_upload('images/mandrill.png', 'image/png')]
               }
             }
      end
    end
    assert_redirected_to article_url(@article)
  end

  test "should destroy article" do
    assert_difference -> { FullMetalBody::BlockedAction.count } => 1,
                      -> { Article.count } => -1 do
      delete article_url(@article)
    end
    assert_redirected_to articles_url
  end

  private

  def article_whitelist
    {
      'article' => {
        'title' => {
          'type' => 'string'
        },
        'content' => {
          'type' => 'string'
        },
        'article_tags_attributes' => {
          'type' => 'array',
          'properties' => {
            'id' => {
              'type' => 'number'
            },
            'tag_id' => {
              'type' => 'number'
            }
          }
        },
        'images' => {
          "type" => "array",
          "properties" => {
            "type" => "file",
            "options" => {
              "content_type" => "image/png",
              "file_size" => 1.megabytes,
            }
          }
        }
      }
    }
  end
end
