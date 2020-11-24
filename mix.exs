defmodule PostgresqlUri.MixProject do
  use Mix.Project

  def project do
    [
      app: :postgresql_uri,
      version: "0.1.0",
      elixir: "~> 1.0",
      start_permanent: Mix.env() == :prod,
      description: "Parse PostgreSQL URIs into keyword lists (for use with Postgrex).",
      source_url: "https://github.com/blinkingtwelve/postgresql_uri",
      homepage_url: "https://github.com/blinkingtwelve/postgresql_uri",
      package: [
        maintainers: ["Wicher Minnaard <wicher@nontrivialpursuit.org>"],
        contributors: ["Wicher Minnaard <wicher@nontrivialpursuit.org>"],
        licenses: ["LGPL-3.0-or-later"],
        links: %{"GitHub" => "https://github.com/blinkingtwelve/postgresql_uri"},
      ],
      docs: [
        extras: ["README.md"],
        formatter: "html",
        authors: ["Wicher Minnaard <wicher@nontrivialpursuit.org>"],
        main: "readme"
      ],
      deps: [
        {:ex_doc, "~> 0.23", only: :dev, runtime: false}
      ]
    ]
  end
end
