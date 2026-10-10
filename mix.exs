defmodule Setzkasten.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/shostakovich/setzkasten"

  def project do
    [
      app: :setzkasten,
      version: @version,
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      start_permanent: false,
      deps: deps(),
      aliases: aliases(),
      description:
        "HEEx components and design system (daisyUI theme and patches) for Phoenix admin backends.",
      package: package(),
      docs: docs(),
      name: "Setzkasten",
      source_url: @source_url
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  def cli do
    [preferred_envs: [ci: :test]]
  end

  defp elixirc_paths(:dev), do: ["lib", "dev/lib"]
  defp elixirc_paths(:test), do: ["lib", "dev/lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix_live_view, "~> 1.2"},
      {:phoenix_html, "~> 4.1"},
      {:jason, "~> 1.4", only: [:dev, :test]},
      {:bandit, "~> 1.5", only: [:dev, :test]},
      {:tailwind, "~> 0.4", only: :dev, runtime: false},
      {:esbuild, "~> 0.10", only: :dev, runtime: false},
      {:daisyui,
       github: "saadeghi/daisyui",
       tag: "v5.5.20",
       sparse: "packages/bundle",
       app: false,
       compile: false,
       depth: 1,
       only: :dev},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:ex_doc, "~> 0.38", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      dev: ["assets.build", "run dev/start.exs"],
      "assets.build": ["compile", "tailwind catalog", "esbuild catalog"],
      ci: [
        "compile --warnings-as-errors --force",
        "format --check-formatted",
        "credo --strict",
        "test"
      ]
    ]
  end

  defp package do
    [
      licenses: ["Unlicense"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib priv guides mix.exs README.md LICENSE CHANGELOG.md .formatter.exs)
    ]
  end

  defp docs do
    [
      main: "readme",
      logo: "guides/assets/setzkasten-128.png",
      assets: %{"guides/assets" => "guides/assets"},
      source_ref: "v#{@version}",
      extras: ["README.md", "guides/design-system.md", "CHANGELOG.md"],
      groups_for_modules: [
        Components: ~r/Setzkasten\.Components\./
      ]
    ]
  end
end
