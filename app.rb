# frozen_string_literal: true

require "date"
require "json"
require "rack/utils"
require "sinatra/base"
require "marsdate"

class MarscalApi < Sinatra::Base
  DATE_PATTERN = /\A\d{4}-\d{2}-\d{2}\z/
  TIME_PATTERN = /\A\d{2}:\d{2}:\d{2}\z/

  configure do
    set :show_exceptions, false
    set :raise_errors, false
  end

  helpers do
    def json_response(value, status: 200)
      content_type :json
      halt status, JSON.generate(value)
    end

    def parse_date(name)
      value = params[name]
      raise ArgumentError, "#{name} is required in YYYY-MM-DD form" unless DATE_PATTERN.match?(value.to_s)

      value
    end

    def parse_time(name)
      value = params[name]
      return [0, 0, 0] if value.nil? || value.empty?
      raise ArgumentError, "#{name} must be in HH:MM:SS form" unless TIME_PATTERN.match?(value)

      value.split(":").map(&:to_i)
    end

    def earth_to_mars
      year, month, day = parse_date("edate").split("-").map(&:to_i)
      hour, minute, second = parse_time("etime")
      MarsDateTime.new(DateTime.new(year, month, day, hour, minute, second))
    rescue Date::Error
      raise ArgumentError, "edate is not a valid Earth date"
    end

    def mars_to_earth
      year, month, sol = parse_date("mdate").split("-").map(&:to_i)
      hour, minute, second = parse_time("mtime")
      MarsDateTime.new(year, month, sol, hour, minute, second).earth_date
    rescue Date::Error
      raise ArgumentError, "mdate is not a valid Mars date"
    end

    def html_error(error)
      content_type :html
      status 400
      "Error: #{Rack::Utils.escape_html(error.message)}"
    end

    def format_now(value, format)
      return value.inspect if format.nil? || format.empty?

      expanded = format.each_char.map { |character| "%#{character} " }.join
      value.respond_to?(:format) ? value.format(expanded) : value.strftime(expanded)
    end
  end

  get "/" do
    content_type :html
    help_info
  end

  get "/user" do
    content_type :html
    help_info
  end

  get "/e2m" do
    json_response(earth_to_mars.as_json)
  rescue ArgumentError => error
    json_response({ error: error.message }, status: 400)
  end

  get "/user/e2m" do
    content_type :html
    "Result is: <b>#{Rack::Utils.escape_html(earth_to_mars.to_s)}</b>"
  rescue ArgumentError => error
    html_error(error)
  end

  get "/m2e" do
    json_response(mars_to_earth.iso8601)
  rescue ArgumentError => error
    json_response({ error: error.message }, status: 400)
  end

  get "/user/m2e" do
    content_type :html
    "Result is: <b>#{Rack::Utils.escape_html(mars_to_earth.iso8601)}</b>"
  rescue ArgumentError => error
    html_error(error)
  end

  get "/now" do
    json_response(MarsDateTime.now.as_json)
  end

  get "/user/now" do
    content_type :html
    format = params["format"]
    earth = format_now(Time.now, format)
    mars = format_now(MarsDateTime.now, format)
    "<font size=+1><tt>Earth:</tt></font> #{Rack::Utils.escape_html(earth)}<br>" \
      "<font size=+1><tt>Mars :</tt></font> #{Rack::Utils.escape_html(mars)}"
  end

  get "/form" do
    content_type :html
    <<~HTML
      <form action="convert_e2m" method="post">
        <label>Enter date <input name="bday" placeholder="YYYY-MM-DD"></label>
        <button type="submit">Convert</button>
      </form>
    HTML
  end

  post "/convert_e2m" do
    params["edate"] = params["bday"]
    content_type :html
    "Result is: <b>#{Rack::Utils.escape_html(earth_to_mars.to_s)}</b><br>"
  rescue ArgumentError => error
    html_error(error)
  end

  not_found do
    json_response({ error: "Not found" }, status: 404)
  end

  error do
    json_response({ error: "Internal server error" }, status: 500)
  end

  private

  def help_info
    <<~HTML
      <!doctype html>
      <html lang="en">
        <head><meta charset="utf-8"><title>Mars Calendar API</title></head>
        <body>
          <h1>Mars Calendar API</h1>
          <p>JSON endpoints:</p>
          <ul>
            <li><code>GET /api/now</code></li>
            <li><code>GET /api/e2m?edate=YYYY-MM-DD&amp;etime=HH:MM:SS</code></li>
            <li><code>GET /api/m2e?mdate=YYYY-MM-DD&amp;mtime=HH:MM:SS</code></li>
          </ul>
          <p>Human-readable equivalents are under <code>/api/user</code>, including
             <code>/api/user/now</code>, <code>/api/user/e2m</code>, and
             <code>/api/user/m2e</code>.</p>
          <p><a href="/api/form">Open the Earth-to-Mars conversion form</a>.</p>
          <p>Time parameters are optional and default to midnight. Martian input
             times use Mars eXtended Time (MXT).</p>
          <p>Mars JSON uses the fields supplied by MarsDate 2:
             <code>msd</code>, <code>year</code>, <code>month</code>,
             <code>sol</code>, <code>epoch_sol</code>, <code>year_sol</code>,
             <code>dow</code>, <code>day_of_week</code>, <code>mtc</code>, and
             <code>mxt</code>.</p>
        </body>
      </html>
    HTML
  end
end
