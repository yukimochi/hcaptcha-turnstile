Hcaptcha.configure do |config|
  config.site_key  = Rails.application.credentials.hcaptcha[:site_key]
  config.secret_key = Rails.application.credentials.hcaptcha[:secret_key]
end
