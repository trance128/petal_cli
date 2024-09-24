defmodule PetalInstaller.ElixirHeexClassExtractor do
  def extract_from_file(file_path) do
    case File.read(file_path) do
      {:ok, content} -> extract_classes(content)
      {:error, reason} -> {:error, "Failed to read file: #{reason}"}
    end
  end

  def extract_classes(content) do
    {_ast, acc} = Code.string_to_quoted!(content)
    |> Macro.prewalk([], &collect_classes/2)

    Enum.reverse(acc)
  end

  defp collect_classes({:sigil_H, _, [{:<<>>, _, [heex_content]}, _]} = node, acc) do
    classes = extract_classes_from_heex(heex_content)
    {node, classes ++ acc}
  end

  defp collect_classes(node, acc) do
    {node, acc}
  end

  defp extract_classes_from_heex(heex_content) do
    # Regex to match class attributes, including multi-line and Elixir expressions
    class_regex = ~r/class=(\{[^}]+\}|"[^"]+")/s

    Regex.scan(class_regex, heex_content)
    |> Enum.map(fn [_, class_content] ->
      class_content
      |> String.trim_leading("{")
      |> String.trim_trailing("}")
      |> String.trim("\"")
      |> String.trim
    end)
  end

end
