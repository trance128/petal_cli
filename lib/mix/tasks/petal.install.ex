defmodule Mix.Tasks.Petal.Install do
  use Mix.Task

  @shortdoc "Installs Petal UI components"

  ## all valid components
  @components [
    "accordion",
    "alert",
    "avatar",
    "badge",
    "breadcrumbs",
    "button",
    "card",
    "container",
    "dropdown",
    "form",
    "helpers",
    "icon",
    "input",
    "link",
    "loading",
    "menu",
    "modal",
    "pagination",
    "pagination_internal",
    "progress",
    "rating",
    "skeleton",
    "slide_over",
    "table",
    "tabs",
    "typography",
    "user_dropdown_menu",
  ]

  def run(args) do
    IO.inspect(args, label: "args")

    {opts, component_names, _} =
      OptionParser.parse(args,
        switches: [list: :boolean, setup: :boolean, all: :boolean],
        aliases:  [l: :list, s: :setup, a: :all]
      )

      IO.inspect(opts, label: "opts")
      IO.inspect(component_names, label: "component_names")

    case opts do
      [all: true]   -> do_all()
      [list: true]  -> list_components()
      [setup: true] -> setup()
      _             -> fetch_components(component_names)
    end
  end

  defp do_all do
    with  :ok <- phoenix_project?(),
          :ok <- copy_petals_css(),
          :ok <- update_css_imports(),
          {:ok, project_name} <- get_project_name(),
          :ok <- add_alpine_js(project_name),
          :ok <- update_tailwind_config(),
          :ok <- copy_all_components(project_name)
    do
      IO.puts "\n\n🎊 Finished 🎊\n\n"
    else
      {:error, reason} -> IO.puts reason
    end
  end

  defp copy_petals_css() do
    source_path = Path.join(["deps", "petal_components", "assets", "default.css"])
    to_path = Path.join(["assets", "css", "petals_default.css"])

    case File.cp(source_path, to_path) do
      :ok               ->
            :ok
      {:error, reason}  ->
            {:error, "Failed to copy petals' default.css: #{reason}"}
    end
  end

  defp update_css_imports do
    app_css_path = Path.join(["assets", "css", "app.css"])
    import_statement = "@import \"./petals_default.css\";\n"

    case File.read(app_css_path) do
      {:ok, existing_content} ->
            if String.contains?(existing_content, import_statement) do
              :ok
            else
              new_content = import_statement <> existing_content
              case File.write(app_css_path, new_content) do
                :ok               ->
                    :ok
                {:error, reason}  ->
                    {:error, "Failed to append '#{import_statement}' to 'app.css': #{reason}"}
              end
            end

        {:error, :enoent}     ->
            case File.write(app_css_path, import_statement) do
              :ok               ->
                  :ok
              {:error, reason}  ->
                  {:error, "Failed to write previously nonexistent app.css file: #{reason}"}
            end
        {:error, reason}      ->
            {:error, "Failed to read app.css: #{reason}"}
    end
  end

  defp add_alpine_js(project_name) do
    root_layout_path = Path.join(["lib", "#{project_name}_web", "components", "layouts", "root.html.heex"])

    case File.read(root_layout_path) do
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
              updated_content = get_updated_root_layout_content(content, alpine_collapse_script)
              write_updated_root_layout_content(root_layout_path, updated_content)

          has_collapse?                 ->
              IO.puts "Root layout contains alpine js collapse script; core script will be added"
              updated_content = get_updated_root_layout_content(content, alpine_core_script)
              write_updated_root_layout_content(root_layout_path, updated_content)

          true                          ->
              updated_content = get_updated_root_layout_content(content, "#{alpine_core_script}\n    #{alpine_collapse_script}")
              write_updated_root_layout_content(root_layout_path, updated_content)
        end

      {:error, :enoent} ->
          {:error, "Root layout not found at #{root_layout_path}"}

      {:error, reason} ->
          {:error, "Failed to read root layout: #{reason}"}
    end
  end

  defp get_updated_root_layout_content(content, script), do: String.replace(content, "<head>", "<head>\n    #{script}\n", global: false)

  defp write_updated_root_layout_content(root_layout_path, updated_content) do
    case File.write(root_layout_path, updated_content) do
      :ok               ->
          :ok
      {:error, reason}  ->
          {:error, "Failed to add Alpine JS scripts to root layout: #{reason}"}
    end
  end


  defp update_tailwind_config do
    config_path = Path.join(["assets", "tailwind.config.js"])

    case File.read(config_path) do
      {:ok, content} ->
          updated_content =
            content
            |> add_colors_import()
            |> add_color_palette()

          case File.write(config_path, updated_content) do
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
    default_colors = [
      primary:    "colors.blue",
      secondary:  "colors.pink",
      success:    "colors.green",
      danger:     "colors.red",
      warning:    "colors.yellow",
      info:       "colors.sky",
      gray:       "colors.gray"
    ]

    case extract_previous_colors(content) do
      {:ok, colors} ->
          updated_color_string = get_updated_color_string(colors, default_colors)

          if updated_color_string != colors do
            String.replace(content, colors, updated_color_string)
          else
            content
          end
      nil ->
          updated_color_string = get_updated_color_string("{\n      }", default_colors)
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

  defp get_updated_color_string(existing_colors, default_colors) do
    Enum.reduce(default_colors, existing_colors,
      fn {key, value}, acc ->
        if String.contains?(acc, "#{key}:") do
          acc
        else
          String.trim_trailing(acc, "}") <> "  #{key}: #{value},\n      }"
        end
    end)
  end

  defp copy_all_components(project_name) do
    source_path = Path.join(["deps", "petal_components", "lib"])
    to_path     = Path.join(["lib", "#{project_name}_web", "components"])

    case File.cp_r(source_path, to_path) do
      {:ok, _}            ->
          :ok
      {:error, reason, _} ->
          {:error, "Error copying components: #{reason}"}
    end
  end

  defp fetch_components([]) do
    IO.puts "Specify component names or use --list to see available components"
  end

  defp fetch_components(component_names) do
    with {:ok, project_name} <- get_project_name() do
      res = Enum.map(component_names, &fetch_component(&1, project_name))

      if Enum.any?(res, &match?({:error, _}, &1)) do
        Enum.each(res, fn
            {:error, reason}  -> IO.puts reason
            _                 -> nil
        end)

        IO.puts "Task Finished"
      else
        IO.puts "\n\n🎊 Finished fetching #{component_names} 🎊\n\n"
      end
    else
      {:error, reason}  -> IO.puts "#{reason}"
    end
  end

  defp fetch_component(name, project_name) do
    cond do
      name == "icon"                   ->
          handle_icon_component(project_name)
      Enum.member?(@components, name)  ->
          copy_specific_component(name, project_name)
      true                             ->
          {:error, "Component #{name} not found"}
    end
  end

  ### Will also fetch any dependencies if they don't already exist in users' project
  defp copy_specific_component(component_name, project_name) do
    source_path = component_source_path(component_name)

    ## TODO add a confirmation if file already exists.  Do you wish to overwrite, or nah?

    extract_and_get_dependencies(source_path, project_name)
    to_path = component_to_path(component_name, project_name)
    copy_file(source_path, to_path, "Error copying component #{component_name}")
  end

  ### Checks for any component dependencies, and installs them if not present
  defp extract_and_get_dependencies(source_path, project_name) do
    content = File.read!(source_path)

    dependencies = extract_dependencies(content)
    Enum.each(dependencies, fn dep ->
      handle_component_dependency(dep, project_name)
    end)
  end

  ### Similar to copy_specific_component, except doesn't ask the user to overwrite files
  ### if user already has the file, no overwrite occurs
  defp handle_component_dependency(component_name, project_name) do
    target_path = component_to_path(component_name, project_name)

    if not File.exists?(target_path) do
      source_path = component_source_path(component_name)
      extract_and_get_dependencies(source_path, project_name)

      copy_file(source_path, target_path, "Error copying component #{component_name}")
    end
  end

  defp extract_dependencies(content) do
    alias_regex   = ~r/alias\s+PetalComponents\.([A-Z][a-zA-Z]+)/
    import_regex  = ~r/import\s+PetalComponents\.([A-Z][a-zA-Z]+)/

    aliases = Regex.scan(alias_regex, content) |> Enum.map(& get_dependency_name/1)
    imports = Regex.scan(import_regex, content) |> Enum.map(& get_dependency_name/1)

    (aliases ++ imports) |> Enum.uniq()
  end

  defp get_dependency_name(scan_result) do
    scan_result
    |> List.last()
    |> Macro.underscore()
  end

  defp copy_file(source_path, to_path, error_message) do
    case File.cp(source_path, to_path) do
      :ok ->
        :ok
      {:error, reason} ->
        {:error, "#{error_message}: #{reason}"}
    end
  end

  defp handle_icon_component(project_name) do
    with  :ok <- copy_specific_component("icon", project_name),
          :ok <- copy_icon_folder(project_name)
    do
          :ok
    end
  end

  defp copy_icon_folder(project_name) do
    source_path = Path.join(["deps", "petal_components", "lib", "petal_components", "icons"])
    to_path     = Path.join(["lib", "#{project_name}_web", "components", "petal_components", "icons"])

    case File.cp_r(source_path, to_path) do
      {:ok, _}            ->
          :ok
      {:error, reason, _} ->
          {:error, "Error copying components: #{reason}"}
    end
  end

  defp setup do
    with  :ok <- phoenix_project?(),
          :ok <- copy_petals_css(),
          :ok <- update_css_imports(),
          {:ok, project_name} <- get_project_name(),
          :ok <- add_alpine_js(project_name),
          :ok <- update_tailwind_config(),
          {:ok, _} <- create_petal_components_folder(project_name),
          :ok <- copy_specific_component("helpers", project_name)
    do
      IO.puts "\n\n🎊 Finished Setup 🎊\n\n"
    else
      {:error, reason} -> IO.puts reason
    end
  end

  defp phoenix_project? do
    if do_phoenix_project?() do
      :ok
    else
      {:error, "Error: This doesn't appear to be a Phoenix project"}
    end
  end

  defp do_phoenix_project? do
    File.exists?("mix.exs") &&
    File.exists?("config/config.exs") &&
    File.exists?("lib") &&
    File.read!("mix.exs") =~ "phoenix"
  end

  defp get_project_name do
    case File.read("mix.exs") do
      {:ok, content}    ->
        case Regex.run(~r/app: :?(\w+)/, content) do
          [_, app_name]   ->
            {:ok, app_name}
          nil             ->
            {:error, "Unable to determine project name from mix.exs"}
        end
      {:error, reason}  ->
          {:error, "Error reading mix.exs: #{reason}"}
    end
  end

  defp create_petal_components_folder(project_name) do
    file_path = Path.join(["lib", "#{project_name}_web", "components", "petal_components"])

    case File.mkdir(file_path) do
      :ok               -> {:ok, file_path}
      {:error, reason}  -> {:error, reason}
    end
  end

  defp list_components do
    Enum.each(@components, &IO.puts/1)
  end

  defp component_source_path(component_name), do: Path.join(["deps", "petal_components", "lib", "petal_components", "#{component_name}.ex"])
  defp component_to_path(component_name, project_name), do: Path.join(["lib", "#{project_name}_web", "components", "petal_components", "#{component_name}.ex"])
end
