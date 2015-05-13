require 'test_helper'

class ImmortusControllerTest < ActionController::TestCase
  test 'should get verify route' do
    get :verify, job_id: '1'
    assert_response :success
  end
end
