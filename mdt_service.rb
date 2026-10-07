require 'sinatra'

require 'marsdate'
require 'json'

require 'open-uri'

class MarsDateTime
  def as_json(options={})
      {
        year:        @year,
        month:       @month,
        sol:         @sol,
        epoch_sol:   @epoch_sol,
        year_sol:    @year_sol,
        shr:         @shr,
        smin:        @smin,
        ssec:        @ssec,
        mems:        @mems,
        dow:         @dow,
        day_of_week: @day_of_week,
        mhrs:        @mhrs,
        mmin:        @mmin,
        msec:        @msec
      }
  end

  def to_json(*options)
      as_json(*options).to_json(*options)
  end
end

# Convert e2m   yyyy.mm.dd-[hh:mm:ss]

# user/...   for humans
# api/...        in json

def e2m(edate, etime)
  raise "Expected date in form yyyy-mm-dd" unless edate =~ /\d{4}-\d{2}-\d{2}/
  data = edate.scan(/(....)-(..)-(..)/).first.map(&:to_i)
  yyyy, mm, dd = *data
  h, m, s = 0, 0, 0
  if etime
    data = etime.scan(/(..):(..):(..)/).first.map(&:to_i)
    h, m, s = *data
  end
  date = DateTime.new(yyyy, mm, dd, h, m, s)
  mdate = MarsDateTime.new(date)
  return mdate
end

def m2e(mdate, mtime)
  raise "Expected date in form yyyy-mm-dd" unless mdate =~ /\d{4}-\d{2}-\d{2}/
  data = mdate.scan(/(....)-(..)-(..)/).first.map(&:to_i)
  yyyy, mm, dd = *data
  h, m, s = 0, 0, 0
  if mtime
    data = mtime.scan(/(..):(..):(..)/).first.map(&:to_i)
    h, m, s = *data
  end
  mdate = MarsDateTime.new(yyyy, mm, dd, h, m, s)
  edate = mdate.earth_date
  return edate
end


=begin
<tt>a</tt>   @day_of_week[0..2]
<tt>A</tt>   @day_of_week
<tt>b</tt>   (@month.odd? ? month_name[2..4] : month_name[0..2])
<tt>B</tt>   month_name
<tt>d</tt>   zsol
<tt>e</tt>   ('%2d' % @sol)
<tt>F</tt>   "#@year-#{zmonth}-#{zsol}"
<tt>H</tt>   zhh
<tt>j</tt>   @year_sol.to_s
<tt>m</tt>   zmonth  # @month.to_s
<tt>M</tt>   zmm
<tt>s</tt>   @msec.to_s  # was: (@mems*1000).to_i.to_s
<tt>S</tt>   zss
<tt>u</tt>   (@dow + 1).to_s
<tt>U</tt>   (@year_sol/7 + 1).to_s
<tt>w</tt>   @dow.to_s
<tt>x</tt>   "#@year/#{zmonth}/#{zsol}"
<tt>X</tt>   "#{zhh}:#{zmm}:#{zss}"
<tt>Y</tt>   @year.to_s
<tt>P</tt>   (" %02d" % @shr)
<tt>Q</tt>   (" %02d" % @smin)
<tt>R</tt>   (" %02d" % @ssec)
=end

def help_info
  <<~HTML
    <h3>Help information</h3>
    <hr>
    Two basic kinds of URL:<br>
    <ul>
      <li><font size=+1><tt>/api/...</tt></font> to return JSON</li>
      <li><font size=+1><tt>/api/user/...</tt></font> to return HTML</li>
    </ul>

    <dl>
      <dt><font size=+1><tt>/api/now</tt></font><br></dt>
      <dd>Return the current date/time on Mars as JSON</dd>
      <br>
      <dt><font size=+1><tt>/api/user/now</tt></font><br></dt>
      <dd>Return the current date/time on Mars (and also return the earth equivalent). This is the only
          instance where <font size=+1><tt>/api</tt> and <tt>/api/user</tt> differ, so the <tt>user</tt></font> version
          is omitted from here on.</dd>

      <br>
      <dt><font size=+1><tt>/api/e2m?edate=yyyy-mm-dd</tt></font></dt>
      <dd>Pass in Earthly year/month/day and return a Martian date/time as JSON</dd>

      <br>
      <dt><font size=+1><tt>/api/e2m?edate=yyyy-mm-dd&etime=hh:mm:ss</tt></font></dt>
      <dd>Pass in Earthly year/month/day with hour/minute/second and return a Martian date/time as JSON</dd>
      <br>

      <dt><font size=+1><tt>/api/m2e?mdate=yyyy-mm-dd</tt></font></dt>
      <dd>Pass in Martian year/month/day and return an Earthly date/time as JSON</dd>

      <br>
      <dt><font size=+1><tt>/api/m2e?mdate=yyyy-mm-dd&mtime=hh:mm:ss</tt></font></dt>
      <dd>Pass in Martian year/month/day with hour/minute/second and return an Earthly date/time as JSON</dd>
    </dl>

      <b>Not yet implemented:</b><br>
      <ul>
        <li>Mars-to-Earth calculations</li>
        <li>Nice error messages</li>
        <li><font size=+1><tt>srtftime</tt></font>-style formatting</li>
      </ul>

      <hr>
      <b>Field definitions</b><br>
      <table>
        <tr><td><font size=+1><tt>year</tt></font></td>
            <td>Martian year</td></tr>
        <tr><td><font size=+1><tt>month</tt></font></td>
            <td>Martian month</td></tr>
        <tr><td><font size=+1><tt>sol</tt></font></td>
            <td>Martian day of month</td></tr>
        <tr><td><font size=+1><tt>epoch_sol</tt></font></td>
            <td>Sols since Martian epoch</td></tr>
        <tr><td><font size=+1><tt>year_sol</tt></font></td>
            <td>Sols since start of Martian year</td></tr>
        <tr><td><font size=+1><tt>shr</tt></font></td>
            <td>Martian hour (NASA stretched time)</td></tr>
        <tr><td><font size=+1><tt>smin</tt></font></td>
            <td>Martian minute (NASA stretched time)</td></tr>
        <tr><td><font size=+1><tt>ssec</tt></font></td>
            <td>Martian second (NASA stretched time)</td></tr>
        <tr><td><font size=+1><tt>mems</tt></font></td>
            <td>? Milliseconds since Martian epoch</td></tr>
        <tr><td><font size=+1><tt>dow</tt></font></td>
            <td>day of week (integer)</td></tr>
        <tr><td><font size=+1><tt>day_of_week</tt></font></td>
            <td>day of week name</td></tr>
        <tr><td><font size=+1><tt>mhrs</tt></font></td>
            <td>Martian hours</td></tr>
        <tr><td><font size=+1><tt>mmin</tt></font></td>
            <td>Martian minutes</td></tr>
        <tr><td><font size=+1><tt>msec</tt></font></td>
            <td>Martian seconds</td></tr>
    </table>
  HTML
end

#####

get '/' do
  help_info
end

get '/user' do
  help_info
end

##

get '/e2m' do
  edate = params['edate']
  etime = params['etime']
  mdate = e2m(edate, etime)
  mdate.to_json
rescue => e
  "Error: #{e}"
end

get '/user/e2m' do
  edate = params['edate']
  etime = params['etime']
  mdate = e2m(edate, etime)
  "Result is: <b>#{mdate}</b>"
rescue => e
  "Error: #{e}"
end

##

get '/m2e' do
  mdate = params['mdate']
  mtime = params['mtime']
  edate = m2e(mdate, mtime)
  edate.to_json
rescue => e
  "Error: #{e}"
end

get '/user/m2e' do
  mdate = params['mdate']
  mtime = params['mtime']
  edate = m2e(mdate, mtime)
  "Result is: <b>#{edate}</b>"
rescue => e
  "Error: #{e}"
end

##

get '/now' do
  mdate = MarsDateTime.now
  mdate.to_json
end

get '/user/now' do
  mdate = MarsDateTime.now
  edate = Time.now
  format = params[:format]
  if format
    fmt = format.gsub(/(.)/) { "%" + $1 + " " }
    edate = edate.strftime(fmt)
    mdate = mdate.strftime(fmt)
  end

  str1 = "<font size=+1><tt>Earth:</tt></font> #{edate.inspect}<br>"
  str2 = "<font size=+1><tt>Mars :</tt></font> #{mdate.inspect}"
  return str1 + str2
end

get '/form' do
  <<~HTML
    <form action="/convert_e2m" method="post">
      Enter date <input name="bday">
      (in form yyyy-mm-dd)
    </form>
  HTML
end

post '/convert_e2m' do
  bday = params[:bday]
  uri = URI.parse("https://marscalendar.org/api/user/e2m?edate=#{bday}")
  text = uri.read
  "#{text}<br>"
end
