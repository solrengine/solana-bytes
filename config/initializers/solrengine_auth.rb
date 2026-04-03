Solrengine::Auth.configure do |config|
  config.domain = ENV.fetch("APP_DOMAIN", "localhost")
  config.nonce_ttl = 5.minutes
  config.after_sign_in_path = "/challenges"
  config.after_sign_out_path = "/"
end

Rails.application.config.after_initialize do
  Solrengine::Auth::ApplicationController.skip_before_action :authenticate! rescue nil
end
