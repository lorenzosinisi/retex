defmodule Graphvix.Mixfile do
  use Mix.Project

  @version "1.0.0"
  @maintainers [
    "Michael Berkowitz"
  ]
  @links %{
    github: "https://github.com/mikowitz/graphvix"
  }

  def project do
    [
      app: :graphvix,
      version: @version,
      description: "Elixir interface for Graphviz",
      package: [
        maintainers: @maintainers,
        licenses: ["MIT"],
        links: @links
      ],
      elixir: "~> 1.3",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      extra_applications: [:logger, :stream_data]
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", github: "elixir-lang/ex_doc", branch: "master", only: [:dev, :test]},
      {:mix_test_watch, "~> 0.2", only: [:dev, :test]},
      {:stream_data, "~> 0.1", only: [:dev, :test]}
    ]
  end
end
