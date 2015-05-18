require 'test_helper'
require 'immortus_empty_strategy'
require 'spy/integration'
require 'minitest/stub_any_instance'

class ImmortusControllerTest < ActionController::TestCase
  extend Minitest::Spec::DSL

  let(:strategy_spy_mock) { Immortus::TrackingStrategy::EmptyStrategy }

  test 'should get verify route' do
    ::Rails.application.config.active_job.stub(:queue_adapter, :test) do
      get :verify, job_id: '1'
    end
    assert_response :success
  end

  test 'success status' do
    strategy_spy_mock.stub_any_instance(:status, :finished_success) do
      Immortus::StrategyFinder.stub(:find, strategy_spy_mock) do
        response = get :verify, job_id: '1'
        response_json = JSON.parse(response.body)
        assert_equal true, response_json["completed"] && response_json["success"]
      end
    end
  end

  test 'error status' do
    strategy_spy_mock.stub_any_instance(:status, :finished_error) do
      Immortus::StrategyFinder.stub(:find, strategy_spy_mock) do
        response = get :verify, job_id: '1'
        response_json = JSON.parse(response.body)
        assert_equal true, response_json["completed"] && !response_json["success"]
      end
    end
  end

  test 'started status' do
    strategy_spy_mock.stub_any_instance(:status, :started) do
      Immortus::StrategyFinder.stub(:find, strategy_spy_mock) do
        response = get :verify, job_id: '1'
        response_json = JSON.parse(response.body)
        assert_equal true, !response_json["completed"]
      end
    end
  end

  test 'created status' do
    strategy_spy_mock.stub_any_instance(:status, :created) do
      Immortus::StrategyFinder.stub(:find, strategy_spy_mock) do
        response = get :verify, job_id: '1'
        response_json = JSON.parse(response.body)
        assert_equal true, !response_json["completed"]
      end
    end
  end
end
