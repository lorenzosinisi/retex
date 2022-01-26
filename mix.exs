defmodule Retex.MixProject do
  use Mix.Project
  @version "0.1.8"

  def project do
    [
      app: :retex,
      version: @version,
      elixir: "~> 1.12",
      aliases: aliases(),
      start_permanent: Mix.env() == :prod,
      ddocs: [extras: ["README.md"], main: "readme", source_ref: "v#{@version}"],
      source_url: "https://github.com/lorenzosinisi/retex",
      description: description(),
      package: package(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        ignore_warnings: ".dialyzer_ignore.exs"
      ]
    ]
  end

  defp description do
    """
    Rete algorithm in Elixir
    """
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Lorenzo Sinisi"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/lorenzosinisi/retex"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:libgraph, "~> 0.7"},
      {:uuid_tools, "~> 0.1.0"},
      {:duration_tc, "~> 0.1.1", only: :dev},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0.0-rc.7", only: [:dev], runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      test: [
        "format",
        "coveralls",
        "credo --strict",
        "sobelow --skip -i Config.HTTPS --verbose"
      ]
    ]
  end
end
