require 'test_helper'

class ImmortusTest < ActiveSupport::TestCase
  test "Immortus is a module" do
    assert_kind_of Module, Immortus
  end

  test "Immortus::Job is a module" do
    assert_kind_of Module, Immortus::Job
  end
end
