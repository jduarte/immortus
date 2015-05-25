require 'test_helper'
require 'immortus_empty_strategy'
require 'spy/integration'
require 'minitest/stub_any_instance'

class ImmortusControllerTest < ActionController::TestCase
  extend Minitest::Spec::DSL

  let(:empty_strategy) { Immortus::TrackingStrategy::EmptyStrategy }

  test 'should get verify route' do
    Immortus::StrategyFinder.stub(:find, empty_strategy) do
      get :verify, job_id: '1'
    end
    assert_response :success
  end

  test 'completed with success' do
    empty_strategy.stub_any_instance(:completed?, true) do
      Immortus::StrategyFinder.stub(:find, empty_strategy) do
        response = get :verify, job_id: '1'
        response_json = JSON.parse(response.body)
        assert_equal true, response_json["completed"]
      end
    end
  end

  test 'not completed' do
    empty_strategy.stub_any_instance(:completed?, false) do
      Immortus::StrategyFinder.stub(:find, empty_strategy) do
        response = get :verify, job_id: '1'
        response_json = JSON.parse(response.body)
        assert_equal true, !response_json["completed"]
      end
    end
  end

  test 'job_id is present in response' do
    Immortus::StrategyFinder.stub(:find, empty_strategy) do
      response = get :verify, job_id: '908ec6f1-e093-4943-b7a8-7c84eccfe417'
      response_json = JSON.parse(response.body)
      assert_equal '908ec6f1-e093-4943-b7a8-7c84eccfe417', response_json["job_id"]
    end
  end
end
