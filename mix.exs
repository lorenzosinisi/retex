defmodule Retex.MixProject do
  use Mix.Project

  def project do
    [
      app: :retex,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:libgraph, "~> 0.7"},
      {:uuid_tools, "~> 0.1.0"},
      {:duration_tc, "~> 0.1.1", only: :dev}
    ]
  end
end
