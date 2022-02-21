require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @article = articles(:one)
    @comment = comments(:one)
  end

  test "should get index" do
    assert_no_difference 'FullMetalBody::BlockedKey.count' do
      get article_comments_url(@article)
    end
    assert_response :success
  end

  test "should get new" do
    assert_no_difference 'FullMetalBody::BlockedKey.count' do
      get new_article_comment_url(@article)
    end
    assert_response :success
  end

  test "should create comment" do
    assert_no_difference 'FullMetalBody::BlockedKey.count' do
      assert_difference("Comment.count") do
        post article_comments_url(@article), params: { comment: { content: @comment.content } }
      end
    end

    assert_redirected_to article_comment_url(@article, Comment.last)
  end

  test "should show comment" do
    assert_no_difference 'FullMetalBody::BlockedKey.count' do
      get article_comment_url(@article, @comment)
    end
    assert_response :success
  end

  test "should get edit" do
    assert_no_difference 'FullMetalBody::BlockedKey.count' do
      get edit_article_comment_url(@article, @comment)
    end
    assert_response :success
  end

  test "should update comment" do
    assert_no_difference 'FullMetalBody::BlockedKey.count' do
      patch article_comment_url(@article, @comment), params: { comment: { content: @comment.content } }
    end
    assert_redirected_to article_comment_url(@article, @comment)
  end

  test "should destroy comment" do
    assert_no_difference 'FullMetalBody::BlockedKey.count' do
      assert_difference("Comment.count", -1) do
        delete article_comment_url(@article, @comment)
      end
    end
    assert_redirected_to article_comments_url(@article)
  end
end
