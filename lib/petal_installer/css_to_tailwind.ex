defmodule PetalInstaller.CssToTailwind do
  import PetalInstaller.CSSParser

  def replace_classes(class_string) do
    cond do
      String.starts_with?(class_string, "[") and String.ends_with?(class_string, "]") ->
        # Handle list expressions
        process_list_expression(class_string)

      String.contains?(class_string, "(") and String.contains?(class_string, ")") ->
        # Handle function-like expressions or conditionals
        process_complex_expression(class_string)

      String.starts_with?(class_string, "@") ->
        # Leave Elixir expressions unchanged
        class_string

      true ->
        # Handle simple string of classes
        process_class_string(class_string)
    end
  end

  defp process_list_expression(expression) do
    # Remove outer brackets and newlines
    content = expression
      |> String.slice(1..-2//1)
      |> String.replace("\n", " ")
      |> String.trim()

    # Split the content by commas, but not within nested structures
    parts = split_preserving_nested(content)
    processed_parts = Enum.map(parts, &process_list_item/1)
    "[" <> Enum.join(processed_parts, ", ") <> "]"
  end

  defp process_list_item(item) do
    trimmed_item = String.trim(item)
    cond do
      String.starts_with?(trimmed_item, "\"") and String.ends_with?(trimmed_item, "\"") ->
        classes = String.slice(trimmed_item, 1..-2//1)
        |> String.split()
        |> Enum.map(&process_class_string/1)
        |> Enum.join(" ")
        "\"#{classes}\""
      String.starts_with?(trimmed_item, "if") or String.starts_with?(trimmed_item, "unless") ->
        process_conditional(trimmed_item)
      String.contains?(trimmed_item, "\#{") ->
        process_interpolation(trimmed_item)
      true ->
        replace_classes(trimmed_item)
    end
  end

  defp process_interpolation(expression) do
    regex = ~r/(\#\{.*?\})/
    Regex.replace(regex, expression, fn _, match ->
      processed = replace_classes(String.slice(match, 2..-2//1))
      "\#{#{processed}}"
    end)
  end

  defp split_preserving_nested(string) do
    regex = ~r/(?:[^,(){}]|\((?:[^()]|\([^()]*\))*\)|\{(?:[^{}]|\{[^{}]*\})*\})*/
    Regex.scan(regex, string)
    |> List.flatten()
    |> Enum.map(&String.trim/1)
    |> Enum.filter(&(&1 != ""))
  end

  defp process_complex_expression(expression) do
    cond do
      String.contains?(expression, "do:") ->
        [condition, classes] = String.split(expression, "do:", parts: 2)
        processed_classes = process_class_string(String.trim(classes))
        "#{String.trim(condition)} do: #{processed_classes}"
      true ->
        expression
    end
  end

  defp process_conditional(conditional) do
    regex = ~r/"([^"]+)"|\#\{(.*?)\}|([^,]+)/
    processed_conditional = Regex.replace(regex, conditional, fn
      _, class, "", "" when class != "" ->
        "\"#{process_class_string(class)}\""
      _, "", interpolation, "" when interpolation != "" ->
        "\#{#{process_interpolation(interpolation)}}"
      _, "", "", expr when expr != "" ->
        process_complex_expression(expr)
      _, match, _, _ -> match
    end)

    if String.contains?(processed_conditional, "if") or String.contains?(processed_conditional, "unless") do
      parts = String.split(processed_conditional, ~r/(if|unless)/, include_captures: true)
      Enum.map_join(parts, fn part ->
        if String.starts_with?(part, "if") or String.starts_with?(part, "unless") do
          part
        else
          replace_classes(part)
        end
      end)
    else
      processed_conditional
    end
  end

  defp process_class_string(class_string) do
    class_string
    |> String.split()
    |> Enum.map(&replace_single_class/1)
    |> Enum.join(" ")
  end

  defp replace_single_class(class) do
    case get_tailwind_classes(class) do
      nil -> class  # If no Tailwind equivalent found, keep the original
      tailwind -> tailwind
    end
  end
end
