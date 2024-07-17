defmodule PetalCli.MixProject do
  use Mix.Project

  def project do
    [
      app: :petal_cli,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      name: "Petal CLI",
      source_url: "https://github.com/trance128/petal_cli"
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
      {:petal_components, "~> 1.9"}
    ]
  end

  defp description do
    "A command-line tool for fetching and installing Petal UI components in Phoenix projects"
  end

  defp package do
    [
      file: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Ovidius Mazuru"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/trance128/petal_cli"}
    ]
  end
end
