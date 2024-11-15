defmodule PetalCli.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/trance128/petal_cli"

  def project do
    [
      app: :petal_cli,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      name: "Petal CLI",
      source_url: @source_url,
      docs: docs()
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
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:petal_components, "~> 2.6"},
      {:salad_ui, "~> 0.4.2"},
    ]
  end

  defp description do
    "A Mix task for easily installing and setting up Petal Components in your Phoenix project."
  end

  defp package do
    [
      file: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Ovidius Mazuru"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/trance128/petal_cli"}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      source_url: @source_url
    ]
  end
end
