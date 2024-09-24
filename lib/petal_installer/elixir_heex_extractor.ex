defmodule PetalInstaller.ElixirHeexExtractor do
  def extract_from_file(file_path) do
    case File.read(file_path) do
      {:ok, content} -> extract_heex_sigils(content)
      {:error, reason} -> "Failed to read file: #{reason}"
    end
  end

  def extract_heex_sigils(content) do
    {_ast, acc} = Code.string_to_quoted!(content)
    |> Macro.prewalk([], &collect_heex_sigils/2)

    Enum.reverse(acc)
  end

  defp collect_heex_sigils({:sigil_H, _, [{:<<>>, _, [content]}, _]} = node, acc) do
    {node, [content | acc]}
  end

  defp collect_heex_sigils(node, acc) do
    {node, acc}
  end
end
