defmodule PetalInstaller.ConfigManager do
  alias   PetalInstaller.FileManager

  @default_petal_colors [
    primary:    "colors.blue",
    secondary:  "colors.pink",
    success:    "colors.green",
    danger:     "colors.red",
    warning:    "colors.yellow",
    info:       "colors.sky",
    gray:       "colors.gray"
  ]

  @default_salad_colors [
    accent: %{
      DEFAULT: "hsl(var(--accent))",
      foreground: "hsl(var(--accent-foreground))"
    },
    background: "hsl(var(--background))",
    border: "hsl(var(--border))",
    card: %{
      DEFAULT: "hsl(var(--card))",
      foreground: "hsl(var(--card-foreground))"
    },
    destructive: %{
      DEFAULT: "hsl(var(--destructive))",
      foreground: "hsl(var(--destructive-foreground))"
    },
    foreground: "hsl(var(--foreground))",
    input: "hsl(var(--input))",
    muted: %{
      DEFAULT: "hsl(var(--muted))",
      foreground: "hsl(var(--muted-foreground))"
    },
    popover: %{
      DEFAULT: "hsl(var(--popover))",
      foreground: "hsl(var(--popover-foreground))"
    },
    primary: %{
      DEFAULT: "hsl(var(--primary))",
      foreground: "hsl(var(--primary-foreground))"
    },
    ring: "hsl(var(--ring))",
    secondary: %{
      DEFAULT: "hsl(var(--secondary))",
      foreground: "hsl(var(--secondary-foreground))"
    }
  ]

  @spec copy_css(atom()) :: :ok | {:error, <<_::16, _::_*8>>}
  def copy_css(framework) do
    {source_path, dest_path} = FileManager.get_paths(framework, :css)
    FileManager.copy(source_path, dest_path, "Failed to copy css files")
  end

  @spec update_css_imports(atom()) :: :ok, {:error, String.t()}
  def update_css_imports(framework) do
    app_css_path = FileManager.get_paths(:app_css)

    import_statement =
      case framework do
        :petal      -> "@import \"./petals_default.css\";\n"
        :salad      -> "@import \"./salad_ui.css\";\n"
      end

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
    root_layout_path = FileManager.get_paths(:root_layout)

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
    case FileManager.write(FileManager.get_paths(:root_layout), updated_content) do
      :ok               ->
          :ok
      {:error, reason}  ->
          {:error, "Failed to add Alpine JS scripts to root layout: #{reason}"}
    end
  end

  @spec update_tailwind_config(atom()) :: :ok | {:error, String.t()}
  def update_tailwind_config(framework) do
    config_path = FileManager.get_paths(:tailwind_config)

    case FileManager.read(config_path) do
      {:ok, content} ->
          updated_content = get_updated_tailwind_content(content, framework)

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

  defp get_updated_tailwind_content(content, :petal) do
    content
    |> add_colors_import()
    |> add_color_palette(:petal)
  end

  defp get_updated_tailwind_content(content, :salad) do
    content
    # adding_color_palette doesn't curretly work right.  Do it manually, or wait till fixed
    # |> add_color_palette(:salad)
    |> update_tailwind_plugins(:salad)
  end

  defp add_colors_import(content) do
    if String.contains?(content, "const colors = require(\"tailwindcss/colors\")") do
      IO.puts "Tailwind config already contains colors import; skipping..."
      content
    else
      "const colors = require(\"tailwindcss/colors\");\n" <> content
    end
  end

  defp add_color_palette(content, framework) do
    case extract_previous_colors(content) do
      {:ok, colors} ->
          updated_color_string = get_updated_color_string(colors, framework)

          if updated_color_string != colors do
            String.replace(content, colors, updated_color_string)
          else
            content
          end
      nil ->
          updated_color_string = get_updated_color_string("{\n      }", framework)
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

  defp get_updated_color_string(existing_colors, :petal) do
    Enum.reduce(@default_petal_colors, existing_colors,
      fn {key, value}, acc ->
        if String.contains?(acc, "#{key}:") do
          acc
        else
          String.trim_trailing(acc, "}") <> "  #{key}: #{value},\n      }"
        end
    end)
  end

  # TODO this doesn't seem to work right
  defp get_updated_color_string(existing_colors, :salad) do
    Enum.reduce(@default_salad_colors, existing_colors, fn {key, value}, acc ->
      if String.contains?(acc, "#{key}:") do
        acc
      else
        case value do
          %{} = nested_value ->
            nested_string = Enum.map_join(nested_value, ", ", fn {k, v} -> "#{k}: \"#{v}\"" end)
            String.trim_trailing(acc, "}") <> " #{key}: { #{nested_string} },\n }"
          _ ->
            String.trim_trailing(acc, "}") <> " #{key}: \"#{value}\",\n }"
        end
      end
    end)
  end

  defp update_tailwind_plugins(content, :salad) do
    animate_regex       = ~r/require.*tailwindcss-animate/
    typography_regex    = ~r/require\(["']@tailwindcss\/typography["']\)/
    forms_regex         = ~r/require\(["']@tailwindcss\/forms["']\)/

    animate_present     = Regex.match?(animate_regex, content)
    typography_present  = Regex.match?(typography_regex, content)
    forms_present       = Regex.match?(forms_regex, content)

    new_plugins = []
    new_plugins = if !animate_present,    do: ["require(\"./js/tailwindcss-animate.js\")" | new_plugins], else: new_plugins
    new_plugins = if !typography_present, do: ["require(\"@tailwindcss/typography\")" | new_plugins],     else: new_plugins
    new_plugins = if !forms_present,      do: ["require(\"@tailwindcss/forms\")" | new_plugins],          else: new_plugins

    if !animate_present, do: add_tailwind_animate_js_file()

    if Enum.empty?(new_plugins) do
      content
    else
      plugins_string = Enum.join(new_plugins, ",\n  ")

      if String.contains?(content, "plugins: [") do
        Regex.replace(~r/plugins:\s*\[/, content, "plugins: [\n  #{plugins_string},\n  ")
      else
        content <> "\nplugins: [\n  #{plugins_string}\n]"
      end
    end
  end

  defp add_tailwind_animate_js_file do
    {source, dest} = FileManager.get_paths(:tw_animate)
    FileManager.copy(source, dest)
  end
end
