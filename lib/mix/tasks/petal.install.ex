defmodule Mix.Tasks.Petal.Install do
  use Mix.Task

  @shortdoc "Instals Petal UI components"

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
    import_statement = "@import \"./petals_default.css\";"

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

  defp copy_all_components(project_name) do
    source_path = Path.join(["deps", "petal_components", "lib"])
    to_path = Path.join(["lib", "#{project_name}_web", "components"])

    case File.cp_r(source_path, to_path) do
      {:ok, _}            ->
          :ok
      {:error, reason, _} ->
          {:error, "Error copying components: #{reason}"}
    end
  end

  defp setup do
    with  :ok                 <- phoenix_project?(),
          {:ok, project_name} <- get_project_name()
    do
      create_petal_components_folder(project_name)
    end
  end

  defp phoenix_project? do
    if do_phoenix_project?() do
      :ok
    else
      IO.puts "Error: This doesn't appear to be a Phoenix project"
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
    dir = Path.join(["lib", "#{project_name}_web", "components"])
    file_path = Path.join(dir, "petal_components")

    case File.mkdir(file_path) do
      :ok               -> {:ok, file_path}
      {:error, reason}  -> {:error, reason}
    end
  end

  defp fetch_components([]) do
    IO.puts "Specify component names or use --list to see available components"
  end

  defp fetch_components(component_names) do
    Enum.each(component_names, &fetch_component/1)
  end

  defp fetch_component(name) do
    case get_component_content(name) do
      # {:ok, content}    -> save_component(name, content)
      # {:error, reason}  -> IO.puts "Error fetching component #{name}: #{reason}"
      _                 -> IO.puts "An unexpected error ocurred"
    end
  end

  defp get_component_content(name) do
    IO.puts "Fake getting #{name}"
  end

  # defp save_component(name, _content) do
  #   IO.puts "fake saving component with name #{name}"
  # end

  defp list_components do
    components = [
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

    Enum.each(components, &IO.puts/1)
  end
end
