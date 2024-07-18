defmodule PetalInstaller.ConfigManager do
  alias   PetalInstaller.FileManager

  @default_colors [
    primary:    "colors.blue",
    secondary:  "colors.pink",
    success:    "colors.green",
    danger:     "colors.red",
    warning:    "colors.yellow",
    info:       "colors.sky",
    gray:       "colors.gray"
  ]

  def copy_petals_css do
    {source_path, to_path} = FileManager.get_css_paths()
    FileManager.copy(source_path, to_path, "Failed to copy css files")
  end

  def update_css_imports do
    app_css_path = FileManager.get_app_css_path()
    import_statement = "@import \"./petals_default.css\";\n"

    case FileManager.read(app_css_path) do
      {:ok, existing_content} ->
            if String.contains?(existing_content, import_statement) do
              :ok
            else
              new_content = import_statement <> existing_content
              case FileManager.write(app_css_path, new_content) do
                :ok               ->
                    :ok
                {:error, reason}  ->
                    {:error, "Failed to append '#{import_statement}' to 'app.css': #{reason}"}
              end
            end

        {:error, :enoent}     ->
            case FileManager.write(app_css_path, import_statement) do
              :ok               ->
                  :ok
              {:error, reason}  ->
                  {:error, "Failed to write previously nonexistent app.css file: #{reason}"}
            end
        {:error, reason}      ->
            {:error, "Failed to read app.css: #{reason}"}
    end
  end

  def add_alpine_js do
    root_layout_path = FileManager.get_root_layout_path()

    case FileManager.read(root_layout_path) do
      {:ok, content} ->
        alpine_core_regex       = ~r/<script[^>]*src="[^"]*alpinejs@[^"]*\/dist\/cdn\.min\.js"[^>]*>/
        alpine_collapse_regex   = ~r/<script[^>]*src="[^"]*alpinejs\/collapse@[^"]*\/dist\/cdn\.min\.js"[^>]*>/

        alpine_core_script      = ~s(<script defer src="https://unpkg.com/alpinejs@3.x.x/dist/cdn.min.js"></script>)
        alpine_collapse_script  = ~s(<script defer src="https://unpkg.com/@alpinejs/collapse@3.x.x/dist/cdn.min.js"></script>)

        has_core?     = Regex.match?(alpine_core_regex, content)
        has_collapse? = Regex.match?(alpine_collapse_regex, content)

        cond do
          has_core? and has_collapse?   ->
              IO.puts("Alpine JS scripts already present; no overwrite")
              :ok

          has_core?                     ->
              IO.puts "Root layout contains alpine js core; alpine collapse script will be added"
              get_updated_root_layout_content(content, alpine_collapse_script)
              |> write_updated_root_layout_content()

          has_collapse?                 ->
              IO.puts "Root layout contains alpine js collapse script; core script will be added"
              get_updated_root_layout_content(content, alpine_core_script)
              |> write_updated_root_layout_content()

          true                          ->
              get_updated_root_layout_content(content, "#{alpine_core_script}\n    #{alpine_collapse_script}")
              |> write_updated_root_layout_content()
        end

      {:error, :enoent} ->
          {:error, "Root layout not found at #{root_layout_path}"}

      {:error, reason} ->
          {:error, "Failed to read root layout: #{reason}"}
    end
  end

  defp get_updated_root_layout_content(content, script), do: String.replace(content, "<head>", "<head>\n    #{script}\n", global: false)

  defp write_updated_root_layout_content(updated_content) do
    case FileManager.write(FileManager.get_root_layout_path(), updated_content) do
      :ok               ->
          :ok
      {:error, reason}  ->
          {:error, "Failed to add Alpine JS scripts to root layout: #{reason}"}
    end
  end


  def update_tailwind_config do
    config_path = FileManager.get_tailwind_config_path()

    case FileManager.read(config_path) do
      {:ok, content} ->
          updated_content =
            content
            |> add_colors_import()
            |> add_color_palette()

          case FileManager.write(config_path, updated_content) do
            :ok               ->
                :ok
            {:error, reason}  ->
                {:error, "Failed to write updated tailwind config: #{reason}"}
          end

      {:error, :enoent} ->
          {:error, "tailwind.config.js not found at #{config_path}.  Is tailwind installed?"}

      {:error, reason}  ->
          {:error, "Failed to read tailwind.config.js: #{reason}"}
    end
  end

  defp add_colors_import(content) do
    if String.contains?(content, "const colors = require(\"tailwindcss/colors\")") do
      IO.puts "Tailwind config already contains colors import; skipping..."
      content
    else
      "const colors = require(\"tailwindcss/colors\");\n" <> content
    end
  end

  defp add_color_palette(content) do
    case extract_previous_colors(content) do
      {:ok, colors} ->
          updated_color_string = get_updated_color_string(colors)

          if updated_color_string != colors do
            String.replace(content, colors, updated_color_string)
          else
            content
          end
      nil ->
          updated_color_string = get_updated_color_string("{\n      }")
          String.replace(content, "extend: {", "extend: {\n      colors: #{updated_color_string},", global: false)
    end
  end

  defp extract_previous_colors(content) do
    case Regex.run(~r/colors:\s*(\{[^}]+\})/, content) do
      [_, colors_string] ->
        {:ok, colors_string}
      nil ->
        nil
    end
  end

  defp get_updated_color_string(existing_colors) do
    Enum.reduce(@default_colors, existing_colors,
      fn {key, value}, acc ->
        if String.contains?(acc, "#{key}:") do
          acc
        else
          String.trim_trailing(acc, "}") <> "  #{key}: #{value},\n      }"
        end
    end)
  end
end
