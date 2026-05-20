Rails.application.routes.draw do
  # Auth engine and health check stay outside the locale scope — auth has
  # its own namespace isolation and doesn't need localized URLs.
  mount Solrengine::Auth::Engine, at: "/auth"
  get "up" => "rails/health#show", as: :rails_health_check

  # All host-app routes are available at the bare path (default :en) and
  # under an optional /:locale prefix (e.g. /es/...). The locale constraint
  # keeps the optional segment from greedily swallowing real path segments
  # like "learn".
  scope "(:locale)", locale: /en|es/ do
    resources :accounts, only: [ :show ], param: :address
    post "lookup", to: "accounts#lookup", as: :lookup
    patch "network", to: "networks#update", as: :network

    # Byte Challenge game
    get "challenges", to: "challenges#index", as: :challenges
    get "challenge", to: "challenges#show", as: :challenge
    post "challenge/result", to: "challenges#save_result", as: :save_challenge_result

    # Leaderboard
    get "leaderboard", to: "leaderboard#index", as: :leaderboard

    # Public stats
    get "stats", to: "stats#show"

    # Learn hub — canonical URL is /learn/<category>/<slug> (U22).
    get "learn", to: "learn#index", as: :learn
    get "learn/:category/:slug",
        to: "learn#show",
        as: :learn_entry,
        constraints: { category: /[a-z][a-z0-9-]*/, slug: /[a-z][a-z0-9-]*/ }
    # Single-segment /learn/:slug serves dual duty: render the category
    # landing page when the slug names a category, 301 to the canonical
    # /learn/<category>/<slug> when the slug names a legacy entry. Pre-U22
    # URLs like /learn/mint redirect to /learn/spl-token/mint.
    get "learn/:slug",
        to: "learn#category",
        as: :learn_category,
        constraints: { slug: /[a-z][a-z0-9-]*/ }

    # Legacy /types route: 301 redirect to /learn for SEO continuity.
    get "types", to: redirect("/learn", status: 301), as: :types

    # About page (U19)
    get "about", to: "pages#about", as: :about

    root "pages#home"
  end
end
