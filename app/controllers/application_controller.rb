class ApplicationController < ActionController::Base
  include Solrengine::Auth::Concerns::ControllerHelpers
  allow_browser versions: :modern

  after_action :track_pageview

  private

  BOT_PATTERN = /bot|crawl|spider|slurp|Mediapartners|facebookexternalhit|Twitterbot|LinkedInBot/i

  def track_pageview
    return unless response.content_type&.include?("text/html")
    return if response.redirect?
    return if request.headers["Turbo-Frame"].present?
    return if request.user_agent&.match?(BOT_PATTERN)

    ahoy.track "pageview", page: request.path
  end
end
