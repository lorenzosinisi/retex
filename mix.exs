defmodule Retex.MixProject do
  use Mix.Project
  @version "0.1.8"

  def project do
    [
      app: :retex,
      version: @version,
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      ddocs: [extras: ["README.md"], main: "readme", source_ref: "v#{@version}"],
      source_url: "https://github.com/lorenzosinisi/retex",
      description: description(),
      package: package(),
      deps: deps()
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
      {:sanskrit, git: "https://github.com/lorenzosinisi/sanskrit"}
    ]
  end
end
