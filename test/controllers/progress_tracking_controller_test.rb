require "test_helper"

class ProgressTrackingControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get progress_tracking_index_url
    assert_response :success
  end

  test "should get show" do
    get progress_tracking_show_url
    assert_response :success
  end
end
