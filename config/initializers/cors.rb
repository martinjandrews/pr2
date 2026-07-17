# Public read-only API for the ballfm-landing-hub frontend (a separate app/repo).
# Scoped to /api/* only, so the authenticated HTML/Devise routes keep their
# same-origin-only, cookie-based session posture untouched.
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch('ALLOWED_ORIGIN', 'http://localhost:8080').split(',')

    resource '/api/*',
      headers: :any,
      methods: [:get, :head, :options]
  end
end
