module LearnHelper
  # Renders a Markdown body (from content/learn/*.md) to HTML using kramdown
  # in GFM mode (tables, fenced code, autolinks). Returns html_safe output.
  #
  # Styling is applied by the surrounding wrapper in show.html.erb using
  # arbitrary-variant selectors (e.g. [&_h2]:text-white) — kramdown emits
  # plain semantic HTML and the page CSS does the rest.
  def render_learn_markdown(body)
    return "".html_safe if body.blank?
    html = Kramdown::Document.new(
      body,
      input: "GFM",
      hard_wrap: false,
      syntax_highlighter: nil,
      auto_ids: true
    ).to_html
    html = localize_internal_links(html) unless I18n.locale == I18n.default_locale
    html.html_safe
  end

  # Localized category name/description. English lives in the
  # AccountTaxonomy::Category struct and serves as the i18n default, so only
  # non-default locales need keys under learn.categories.<slug>.
  def category_name(category)
    t("learn.categories.#{category.slug}.name", default: category.name)
  end

  def category_description(category)
    t("learn.categories.#{category.slug}.description", default: category.description)
  end

  private

  # Rewrites root-relative in-app links in rendered Markdown to the active
  # locale (e.g. href="/learn/..." → href="/es/learn/..."). Lets translators
  # write normal /learn links in the body and have them stay in-language.
  # External (https://) and anchor (#) links are untouched.
  INTERNAL_LINK_RE = %r{href="(/(?:learn|accounts|challenges|about)\b)}
  def localize_internal_links(html)
    html.gsub(INTERNAL_LINK_RE, %(href="/#{I18n.locale}\\1))
  end
end
