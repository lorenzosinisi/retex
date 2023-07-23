defmodule Retex.MixProject do
  use Mix.Project
  @source_url "https://github.com/lorenzosinisi/retex"
  @version "0.1.10"

  def project do
    [
      app: :retex,
      version: @version,
      elixir: "~> 1.12",
      aliases: aliases(),
      start_permanent: Mix.env() == :prod,
      source_url: "https://github.com/lorenzosinisi/retex",
      description: description(),
      package: package(),
      deps: deps(),
      docs: docs(),
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

    The Rete algorithm is a powerful rule-based pattern matching algorithm commonly used in the
    field of artificial intelligence and expert systems. It efficiently processes large sets of
    rules and facts to infer conclusions and make decisions. Implementing the Rete algorithm provides
    developers with a flexible and scalable solution
    for rule-based systems. This package offers a set of abstractions and functions to define rules,
    facts, and conditions, and efficiently match them against a working memory.

    By leveraging the concurrent and distributed nature of the Elixir language, the Retex algorithm package
    enables high-performance rule evaluation, making it suitable for real-time applications and systems
    requiring complex decision-making logic. Whether used for business rules, event processing, or other
    intelligent systems, this Elixir package empowers developers to implement rule-based functionality
    with ease and harness the full potential of the Rete algorithm within their Elixir applications.
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
      {:libgraph, "~> 0.16.0"},
      {:uuid_tools, "~> 0.1.0"},
      {:duration_tc, "~> 0.1.1", only: :dev},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev], runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp docs do
    [
      extras: [
        "CHANGELOG.md": [],
        LICENSE: [title: "License"],
        "README.md": [title: "Overview"]
      ],
      assets: "assets",
      main: "readme",
      canonical: "http://hexdocs.pm/retex",
      homepage_url: @source_url,
      source_url: @source_url,
      source_ref: "v#{@version}",
      before_closing_body_tag: &before_closing_body_tag/1
    ]
  end

  defp before_closing_body_tag(:html) do
    """
    <script src="https://unpkg.com/mermaid@9.1.7/dist/mermaid.min.js"></script>
    <script>
      document.addEventListener("DOMContentLoaded", function () {
        mermaid.initialize({ startOnLoad: false });
        let id = 0;
        for (const codeEl of document.querySelectorAll("pre code.mermaid")) {
          const preEl = codeEl.parentElement;
          const graphDefinition = codeEl.textContent;
          const graphEl = document.createElement("div");
          const graphId = "mermaid-graph-" + id++;
          mermaid.render(graphId, graphDefinition, function (svgSource, bindListeners) {
            graphEl.innerHTML = svgSource;
            bindListeners && bindListeners(graphEl);
            preEl.insertAdjacentElement("afterend", graphEl);
            preEl.remove();
          });
        }
      });
    </script>
    """
  end

  defp before_closing_body_tag(_), do: ""

  defp aliases do
    [
      test: [
        "format",
        "coveralls",
        "credo",
        "sobelow --skip -i Config.HTTPS --verbose"
      ]
    ]
  end
end
