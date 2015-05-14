require 'test_helper'
require 'immortus_empty_strategy'
require 'spy/integration'

class ImmortusControllerTest < ActionController::TestCase
  extend Minitest::Spec::DSL

  let(:strategy_spy_mock) { Spy.mock(Immortus::TrackingStrategy::EmptyStrategy) }

  test 'should get verify route' do
    ::Rails.application.config.active_job.stub(:queue_adapter, :test) do
      get :verify, job_id: '1'
    end
    assert_response :success
  end

  test 'success status' do
    Spy.on(strategy_spy_mock, :status).and_return(:finished_success)

    ::Rails.application.config.active_job.stub(:queue_adapter, :test) do
      Immortus::StrategyFinder.find.stub(:new, strategy_spy_mock) do
        response = get :verify, job_id: '1'
        response_json = JSON.parse(response.body)
        assert_equal true, response_json["completed"] && response_json["success"]
      end
    end
  end

  test 'error status' do
    Spy.on(strategy_spy_mock, :status).and_return(:finished_error)

    ::Rails.application.config.active_job.stub(:queue_adapter, :test) do
      Immortus::StrategyFinder.find.stub(:new, strategy_spy_mock) do
        response = get :verify, job_id: '1'
        response_json = JSON.parse(response.body)
        assert_equal true, response_json["completed"] && !response_json["success"]
      end
    end
  end

  test 'started status' do
    Spy.on(strategy_spy_mock, :status).and_return(:started)

    ::Rails.application.config.active_job.stub(:queue_adapter, :test) do
      Immortus::StrategyFinder.find.stub(:new, strategy_spy_mock) do
        response = get :verify, job_id: '1'
        response_json = JSON.parse(response.body)
        assert_equal true, !response_json["completed"] && response_json["success"]
      end
    end
  end

  test 'created status' do
    Spy.on(strategy_spy_mock, :status).and_return(:created)

    ::Rails.application.config.active_job.stub(:queue_adapter, :test) do
      Immortus::StrategyFinder.find.stub(:new, strategy_spy_mock) do
        response = get :verify, job_id: '1'
        response_json = JSON.parse(response.body)
        assert_equal true, !response_json["completed"] && response_json["success"]
      end
    end
  end
end
