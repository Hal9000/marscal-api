# marscal-api

A small Rack/Sinatra service for the Martian Common Era calendar API used by
[marscalendar.org](https://marscalendar.org/). Conversion is provided by
MarsDate 2.0.1.

## Run locally

Ruby 3.4 is recommended.

```sh
bundle install
bundle exec puma -C config/puma.rb
```

The development server listens on `http://localhost:4567`. Run the tests with:

```sh
bundle exec ruby -Itest test/app_test.rb
```

## API

The application routes are rooted at `/`. In production, Apache removes the
external `/api` prefix when proxying requests to the application.

| External route | Response |
| --- | --- |
| `GET /api` | API help (HTML) |
| `GET /api/now` | Current Martian date and time (JSON) |
| `GET /api/e2m?edate=YYYY-MM-DD&etime=HH:MM:SS` | Earth-to-Mars conversion (JSON) |
| `GET /api/m2e?mdate=YYYY-MM-DD&mtime=HH:MM:SS` | Mars-to-Earth conversion (JSON) |
| `GET /api/user/now` | Current Earth and Mars times (HTML) |
| `GET /api/user/e2m?...` | Earth-to-Mars conversion (HTML) |
| `GET /api/user/m2e?...` | Mars-to-Earth conversion (HTML) |
| `GET /api/form` | Earth-to-Mars HTML form |
| `POST /api/convert_e2m` | Form conversion result (HTML) |

Time parameters are optional and default to midnight. Martian input times use
Mars eXtended Time (MXT). Invalid parameters return HTTP 400; unexpected
failures return HTTP 500 without exposing exception details.

## Deployment guide

These are instructions only. Deploying the service and changing the live
server require explicit approval.

The planned location is `/opt/apps/marscal-api`, running as `hal9000`. After
checking out a release:

```sh
cd /opt/apps/marscal-api
bundle config set --local without test
bundle install
RACK_ENV=production bundle exec puma -C config/puma.rb
```

Production mode binds Puma only to `127.0.0.1:4567`, where the existing Apache
`/api` proxy expects it.

An example systemd unit:

```ini
[Unit]
Description=Mars Calendar API
After=network.target

[Service]
Type=simple
User=hal9000
WorkingDirectory=/opt/apps/marscal-api
Environment=RACK_ENV=production
Environment=PATH=/home/hal9000/.rbenv/shims:/home/hal9000/.rbenv/bin:/usr/local/bin:/usr/bin:/bin
ExecStart=/home/hal9000/.rbenv/shims/bundle exec puma -C config/puma.rb
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Install and start that unit only after approval. Apache should continue serving
the static site and proxying only `/api`; this service does not require changes
to `/var/www/marscalendar`.