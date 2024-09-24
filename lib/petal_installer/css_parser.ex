defmodule PetalInstaller.CSSParser do
  use     GenServer
  import  CssParser

  def start_link(css_file_path) do
    GenServer.start_link(__MODULE__, css_file_path, name: __MODULE__)
  end

  def init(css_file_path) do
    :ets.new(:css_classes, [:set, :protected, :named_table])
    :ets.new(:css_class_list, [:set, :protected, :named_table])
    parse_css_file(css_file_path)

    {:ok, %{}}
  end

  def get_tailwind_classes(class) do
    # IO.puts("Looking for class #{class}")
    case :ets.lookup(:css_classes, class) do
      [{^class, tailwind_classes}]  ->
        # IO.puts("Got the tailwind classes, which are #{tailwind_classes}")
        tailwind_classes
      []                            ->
        # IO.puts("Did not find the correct tailwind classes")
        nil
    end
  end

  def get_ordered_class_list do
    :ets.tab2list(:css_class_list)
    |> Enum.map(fn {_, class} -> class end)
    |> Enum.sort(&( &1 >= &2))
  end

  defp parse_css_file(css_file_path) do
    content = parse(css_file_path)

    content
    |> Enum.each(&parse_css_rule/1)
  end

  defp parse_css_rule(%{rules: rules, selectors: selectors} = _parsed_css) do
    class =
      selectors |>
      String.replace_prefix(".", "")

    processed_rules =
      rules
      |> String.trim()
      |> process_tailwind_rules()

    :ets.insert(:css_classes, {class, processed_rules})
    :ets.insert(:css_class_list, {class, class})
  end

  defp process_tailwind_rules(rules) do
    rules
    |> String.split(";")
    |> Enum.map(&process_single_rule/1)
    |> Enum.join(" ")
    |> String.trim()
  end

  defp process_single_rule(rule) do
    rule
    |> String.trim()
    |> String.replace_prefix("@apply ", "")
    |> String.replace_suffix(";", "")
  end
end
