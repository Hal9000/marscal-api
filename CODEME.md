PROJECT: marscal-api

Goal:
Build a modern Ruby service that restores the API used by the existing static marscalendar.org website.

Important constraints:
- Create a separate repository named marscal-api.
- Leave the static marscalendar.org site in place.
- Do not integrate this with Gymnos yet.
- Do not make live server changes without explicit approval.
- Keep the service small; do not create elaborate infrastructure.

Current server state:
- Static site: https://marscalendar.org/
- Static site works and returns HTTP 200.
- DocumentRoot: /var/www/marscalendar
- Apache currently proxies:
    /api → http://localhost:4567/
- Nothing is listening on port 4567.
- API requests therefore return HTTP 503.
- No systemd service, cron entry, or other startup mechanism exists.
- The old service last ran in June 2022 using Ruby 2.5, Sinatra 2.2, and WEBrick.
- Current server Ruby is 3.4.10 through:
    /home/hal9000/.rbenv
- Current Ruby installation does not have Sinatra or MarsDate installed.

Static-site API usage:
- GET /api
- GET /api/user/now
- GET /api/form

Old API routes:
- GET /
- GET /user
- GET /now
- GET /user/now
- GET /e2m?edate=YYYY-MM-DD&etime=HH:MM:SS
- GET /user/e2m?edate=YYYY-MM-DD&etime=HH:MM:SS
- GET /m2e?mdate=YYYY-MM-DD&mtime=HH:MM:SS
- GET /user/m2e?mdate=YYYY-MM-DD&mtime=HH:MM:SS
- GET /form
- POST /convert_e2m

Apache strips the external /api prefix before forwarding, so the backend routes should remain rooted at /.

Known old-code problem:
The form currently submits to /convert_e2m. Externally, it must submit to /api/convert_e2m, or use a relative action that resolves there.

MarsDate dependency:
- RubyGems contains only old MarsDate 1.1.7 from 2019.
- Current MarsDate source identifies itself as 2.0.0.
- It has not been published as a gem or tagged as a release.
- Use the Git repository pinned to this exact commit:

    gem "marsdate",
        git: "https://github.com/Hal9000/MarsDate.git",
        ref: "e65761a33217df445fec9a89d4450ea3171d7f9f"

MarsDate 2.0 notes:
- It already implements as_json and to_json. Do not monkeypatch them.
- It uses format rather than strftime.
- Old internal fields such as @shr, @smin, @ssec, @mems, @mhrs, @mmin, and @msec are obsolete.
- Use the documented public API instead of reading instance variables.

Expected project structure:
- Gemfile
- Gemfile.lock
- Rack-compatible application
- Puma
- Request tests for the API routes
- README with local run instructions
- Bind to 127.0.0.1:4567 in production
- Return proper HTTP status codes and JSON content types
- Do not expose exception details as successful HTTP 200 responses

Deployment direction, later:
- Run under systemd.
- Restart automatically after failure/reboot.
- Apache continues serving static files and proxying only /api.
- This deployment is not yet a Gymnos responsibility.

Relevant server audit account:
- gymnos-audit@gymnos.media
- Read-only; no sudo.
- Another Cloud Agent may not possess the private key. Ask before assuming access.