defmodule Mix.Tasks.Petal.Install do
  use     Mix.Task
  alias   PetalInstaller.{ComponentManager, FileManager, ConfigManager, ProjectHelper, Constants}

  @shortdoc "Installs Petal UI components "

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
      _             -> ComponentManager.fetch_components(component_names)
    end
  end

  defp do_all do
    with  :ok <- ProjectHelper.phoenix_project?(),
          :ok <- ConfigManager.copy_petals_css(),
          :ok <- ConfigManager.update_css_imports(),
          {:ok, project_name} <- ProjectHelper.get_project_name(),
          :ok <- FileManager.set_project_name(project_name),
          :ok <- ConfigManager.add_alpine_js(),
          :ok <- ConfigManager.update_tailwind_config(),
          :ok <- ComponentManager.copy_all_components()
    do
      IO.puts "\n\n🎊 Finished 🎊\n\n"
    else
      {:error, reason} -> IO.puts reason
    end
  end

  defp setup do
    with  :ok <- ProjectHelper.phoenix_project?(),
          :ok <- ConfigManager.copy_petals_css(),
          :ok <- ConfigManager.update_css_imports(),
          {:ok, project_name} <- ProjectHelper.get_project_name(),
          :ok <- FileManager.set_project_name(project_name),
          :ok <- ConfigManager.add_alpine_js(),
          :ok <- ConfigManager.update_tailwind_config(),
          {:ok, _} <- FileManager.create_petal_components_folder(),
          :ok <- ComponentManager.copy_specific_component("helpers")
    do
      IO.puts "\n\n🎊 Finished Setup 🎊\n\n"
    else
      {:error, reason} -> IO.puts reason
    end
  end

  defp list_components do
    Enum.each(Constants.components(), &IO.puts/1)
  end
end
