defmodule UUIDTools.MixProject do
  use Mix.Project
  @version "0.1.1"
  def project do
    [
      app: :uuid_tools,
      version: @version,
      elixir: "~> 1.9",
      docs: [extras: ["README.md"], main: "readme", source_ref: "v#{@version}"],
      source_url: "https://github.com/lorenzosinisi/uuid_tools",
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:ex_doc, "~> 0.16", only: :dev},
      {:earmark, "~> 1.2", only: :dev}
    ]
  end

  defp description do
    """
    Tools for UUID generator and utilities aroud it for Elixir.
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Lorenzo Sinisi"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/lorenzosinisi/uuid_tools"}
    ]
  end
end
