module LearnHelper
  # Renders a Markdown body (from content/learn/*.md) to HTML using kramdown
  # in GFM mode (tables, fenced code, autolinks). Returns html_safe output.
  #
  # Styling is applied by the surrounding wrapper in show.html.erb using
  # arbitrary-variant selectors (e.g. [&_h2]:text-white) — kramdown emits
  # plain semantic HTML and the page CSS does the rest.
  def render_learn_markdown(body)
    return "".html_safe if body.blank?
    Kramdown::Document.new(
      body,
      input: "GFM",
      hard_wrap: false,
      syntax_highlighter: nil,
      auto_ids: true
    ).to_html.html_safe
  end
end
