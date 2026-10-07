# frozen_string_literal: true

ENV["RACK_ENV"] = "test"

require "json"
require "minitest/autorun"
require "rack/test"
require_relative "../app"

class MarscalApiTest < Minitest::Test
  include Rack::Test::Methods

  def app
    MarscalApi
  end

  def test_help
    get "/"

    assert last_response.ok?
    assert_equal "text/html", last_response.media_type
    assert_includes last_response.body, "Mars Calendar API"
  end

  def test_now_returns_marsdate_json
    get "/now"

    assert last_response.ok?
    assert_equal "application/json", last_response.media_type
    assert_equal %w[day_of_week dow epoch_sol month msd mtc mxt sol year year_sol],
      JSON.parse(last_response.body).keys.sort
  end

  def test_earth_to_mars
    get "/e2m", edate: "2026-10-07", etime: "12:34:56"

    assert last_response.ok?
    body = JSON.parse(last_response.body)
    expected = MarsDateTime.new(DateTime.new(2026, 10, 7, 12, 34, 56))
    assert_equal expected.as_json.transform_keys(&:to_s), body
  end

  def test_mars_to_earth
    mars = MarsDateTime.new(DateTime.new(2026, 10, 7, 12, 34, 56))

    get "/m2e", mdate: mars.format("%F"), mtime: mars.format_mxt("%X")

    assert last_response.ok?
    assert_equal "application/json", last_response.media_type
    assert_match(/\A2026-10-07T12:34:5\d/, JSON.parse(last_response.body))
  end

  def test_invalid_api_input_is_json_with_bad_request_status
    get "/e2m", edate: "not-a-date"

    assert_equal 400, last_response.status
    assert_equal "application/json", last_response.media_type
    assert_match(/YYYY-MM-DD/, JSON.parse(last_response.body).fetch("error"))
  end

  def test_invalid_human_input_is_html_with_bad_request_status
    get "/user/m2e", mdate: "0001-99-99"

    assert_equal 400, last_response.status
    assert_equal "text/html", last_response.media_type
    assert_includes last_response.body, "Error:"
  end

  def test_human_now
    get "/user/now"

    assert last_response.ok?
    assert_includes last_response.body, "Earth:"
    assert_includes last_response.body, "Mars"
  end

  def test_form_uses_proxy_safe_relative_action
    get "/form"

    assert last_response.ok?
    assert_includes last_response.body, 'action="convert_e2m"'
  end

  def test_form_submission_converts_without_an_http_callback
    post "/convert_e2m", bday: "2026-10-07"

    assert last_response.ok?
    assert_equal "text/html", last_response.media_type
    assert_includes last_response.body, "Result is:"
  end

  def test_unknown_route_is_json_404
    get "/missing"

    assert_equal 404, last_response.status
    assert_equal({ "error" => "Not found" }, JSON.parse(last_response.body))
  end
end
