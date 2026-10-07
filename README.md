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

## Deployment with Gymnos

To create and deploy the service:

```sh
new service marscal-api marscalendar.org /api SOURCE
deploy service marscal-api
```

Gymnos copies the runtime files listed in `manifest.txt` to
`/opt/apps/marscal-api`, assigns the production `PORT`, and starts Puma with
`RACK_ENV=production`. The Puma configuration reads `PORT` and binds only to
`127.0.0.1`; port 4567 remains the default for local or manual use.

Gymnos configures Apache to expose the service beneath `/api` and strips that
prefix before proxying, so the application routes remain rooted at `/`. In
particular, the form's relative `action="convert_e2m"` resolves externally to
`/api/convert_e2m`.

These are deployment instructions only; they do not indicate that a live
deployment has occurred.
