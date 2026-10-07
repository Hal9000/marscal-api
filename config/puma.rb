# frozen_string_literal: true

environment ENV.fetch("RACK_ENV", "development")
threads_count = Integer(ENV.fetch("PUMA_THREADS", 5))
threads threads_count, threads_count

if ENV.fetch("RACK_ENV", "development") == "production"
  bind "tcp://127.0.0.1:4567"
else
  port Integer(ENV.fetch("PORT", 4567))
end
