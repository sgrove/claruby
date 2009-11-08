require 'test_helper'

class RequestTest < ActiveSupport::TestCase
  # Rough test data
  def example_entry
    @example_entry = 'Processing TestController#index (for 194.88.000.00 at 2009-07-10 06:53:28) [GET]
  Parameters: {"back"=>"true", "embed_key"=>"1122334455", "action"=>"index", "ajax"=>"1", "controller"=>"test", "embed"=>"1"}
Rendering template within layouts/application
Rendering test/index
Completed in 31ms (View: 22, DB: 1) | 200 OK [http://www.simpletest.com/embed?ajax=1&back=true&embed_key=1122334455]'
  end

  def parser
    @parser ||= Claruby.new
  end

  def load_log( file )
    parser.parse_log( "#{RAILS_ROOT}/test/fixtures/#{file}" )
  end

  def clear_requests
    Request.delete_all
  end

  test "correctly split requests from log" do
    load_log "request_split_test.fixture.log"
    assert_equal Request.all.count, 3
  end

  test "correctly parse single request" do
    r = parser.parse_log_entry( example_entry )

    assert_equal "TestController", r.controller
    assert_equal "index", r.action
    assert_equal "194.88.000.00", r.ip
    assert_equal Time.parse("2009-07-10 06:53:28"), r.time
    assert_equal "GET", r.http_method
    assert_equal 22, r.view_time
    assert_equal 1, r.db_time
    assert_equal "200 OK", r.http_response
    assert_equal "http://www.simpletest.com/embed?ajax=1&back=true&embed_key=1122334455", r.url
    assert_equal "1122334455", r.embed_key
    assert_equal nil, r.permalink
  end

  test "track path count" do
    clear_requests and load_log "request_path_test.fixture.log"

    assert_equal 6, Request.count # Safety measure

    path = Request.find_by_path("TestController#step_1 -> AnalyticsController#step_2 -> TestController#step_3")

    assert_equal 3, path[0].count
    assert_equal 2, path[1].count
    assert_equal 1, path[2].count
  end

  test "load yaml paths" do
    clear_requests and load_log "request_path_test.fixture.log"

    assert_equal 6, Request.count # Safety measure

    paths = Request.paths_from_yaml( "#{RAILS_ROOT}/test/resources/example_config.yml" )
    path = Request.find_by_path( paths )

    assert_equal 3, path[0].count
    assert_equal 2, path[1].count
    assert_equal 1, path[2].count
  end
end
