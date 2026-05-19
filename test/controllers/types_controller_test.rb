require "test_helper"

# /types was retired in U15 in favor of /learn. The route stays as a
# 301 redirect so external links continue to resolve.
class TypesControllerTest < ActionDispatch::IntegrationTest
  test "GET /types issues a 301 redirect to /learn" do
    get "/types"
    assert_response :moved_permanently
    assert_redirected_to "/learn"
  end
end
