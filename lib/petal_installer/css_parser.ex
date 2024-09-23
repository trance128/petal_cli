defmodule PetalInstaller.CSSParser do
  use GenServer

  def start_link(css_file_path) do
    GenServer.start_link(__MODULE__, css_file_path, name: __MODULE__)
  end

  def init(css_file_path) do
    :ets.new(:css_classes, [:set, :protected, :named_table])
    parse_css_file(css_file_path)

    {:ok, %{}}
  end

  def get_tailwind_classes(class) do
    case :ets.lookup(:css_classes, class) do
      [{^class, tailwind_classes}]  -> tailwind_classes
      []                            -> nil
    end
  end

  defp parse_css_file(css_file_path) do
    File.read!(css_file_path)
    |> String.split("}")
    |> Enum.each(&parse_css_rule/1)
  end

  defp parse_css_rule(rule) do
    case Regex.run(~r/\.([^\s{]+)\s*\{(.+)/, rule) do
      [_, class, styles]  ->
          tailwind_classes = extract_tailwind_classes(styles)
          :ets.insert(:css_classes, {class, tailwind_classes})
      _                   ->
          nil
    end
  end

  defp extract_tailwind_classes(styles) do
    case Regex.run(~r/@apply\s+([^;]+)/, styles) do
      [_, classes] ->
        classes
        |> String.split()
        |> Enum.join(" ")
      _ ->
        ""
    end
  end

end
