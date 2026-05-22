class ApplicationController < ActionController::Base
  include Solrengine::Auth::Concerns::ControllerHelpers
  allow_browser versions: :modern

  around_action :switch_locale
  after_action :track_pageview

  helper_method :locale_switch_path, :other_locale, :loc

  private

  # Sets I18n.locale from the optional /:locale URL segment for the request,
  # restoring the default afterward. Unknown/absent locale → default (:en).
  def switch_locale(&action)
    locale = params[:locale].presence_in(I18n.available_locales.map(&:to_s)) || I18n.default_locale
    I18n.with_locale(locale, &action)
  end

  # Keeps the active locale in any route-helper-generated URLs. The bare
  # path is used for the default locale (no /en prefix).
  def default_url_options
    return {} if I18n.locale == I18n.default_locale
    { locale: I18n.locale }
  end

  # The locale this page is NOT currently in — what the switcher offers.
  def other_locale
    I18n.locale == :es ? :en : :es
  end

  # The current request path rewritten for `target_locale`, preserving the
  # page. Default locale gets the bare path; others get a /<locale> prefix.
  # Views use literal string paths (engine isolation), so the switcher can't
  # rely on route helpers — it rewrites request.path directly.
  def locale_switch_path(target_locale)
    avail = I18n.available_locales.map(&:to_s).join("|")
    stripped = request.path.sub(%r{\A/(?:#{avail})(?=/|\z)}, "")
    stripped = "/" if stripped.empty?
    target_locale.to_s == I18n.default_locale.to_s ? stripped : "/#{target_locale}#{stripped}"
  end

  # Prefixes a literal app path with the active locale (no prefix for the
  # default locale). Views use literal string paths for engine isolation,
  # so this is how in-app links stay within the current language.
  def loc(path)
    return path if I18n.locale == I18n.default_locale
    "/#{I18n.locale}#{path}"
  end

  BOT_PATTERN = /bot|crawl|spider|slurp|Mediapartners|facebookexternalhit|Twitterbot|LinkedInBot/i

  def track_pageview
    return unless response.content_type&.include?("text/html")
    return if response.redirect?
    return if request.headers["Turbo-Frame"].present?
    return if request.user_agent&.match?(BOT_PATTERN)

    ahoy.track "pageview", page: request.path
  end
end
