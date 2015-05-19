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

  test 'finished status' do
    empty_strategy.stub_any_instance(:status, :finished) do
      Immortus::StrategyFinder.stub(:find, empty_strategy) do
        response = get :verify, job_id: '1'
        response_json = JSON.parse(response.body)
        assert_equal true, response_json["completed"] && response_json["success"]
      end
    end
  end

  test 'started status' do
    empty_strategy.stub_any_instance(:status, :started) do
      Immortus::StrategyFinder.stub(:find, empty_strategy) do
        response = get :verify, job_id: '1'
        response_json = JSON.parse(response.body)
        assert_equal true, !response_json["completed"]
      end
    end
  end

  test 'created status' do
    empty_strategy.stub_any_instance(:status, :created) do
      Immortus::StrategyFinder.stub(:find, empty_strategy) do
        response = get :verify, job_id: '1'
        response_json = JSON.parse(response.body)
        assert_equal true, !response_json["completed"]
      end
    end
  end
end
