# This project still a work in progress

# Petal Cli

CLI tool for install petal components

Components are installed into your project's *lib/[app_name_web]/components/* , directory giving you full control over the code

You can now modify and customize components to meet your unique needs

## Installation

### Install globally

Use the following command to install petal_cli globally

```
mix archive.install hex petal_cli
```

### Install locally

Alternatively, add petal_cli to your dependencies in mix.exs if you prefer not to install globally

```
def deps do
  [
    {:petal_cli, "~> 0.1", only: :dev}
  ]
end
```

----------

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `petal_cli` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:petal_cli, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/petal_cli>.

