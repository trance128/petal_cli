defmodule Mix.Tasks.Petal.Install do
  use     Mix.Task
  alias   PetalInstaller.{ComponentManager, FileManager, ConfigManager, ProjectHelper, Constants}

  @shortdoc "Installs Petal UI components "

  @switches [
    list: :boolean,
    install_all: :boolean,
    setup: :boolean,
    help: :boolean,
    no_alpine: :boolean,
    no_rename: :boolean,
    no_tailwind_config: :boolean,
  ]

  @aliases [
    l: :list,
    a: :install_all,
    s: :setup,
    h: :help
  ]

  def run(args) do
    {opts, component_names, _} =
      OptionParser.parse(args,
        switches: @switches,
        aliases:  @aliases
      )

    {:ok, project_name} = ProjectHelper.get_project_name()
    FileManager.set_project_name(project_name)

    cond do
      opts[:help]         -> print_help()
      opts[:list]         -> list_components()
      opts[:install_all]  -> do_install_all(opts)
      true                -> do_install(opts, component_names)
    end
  end

  defp do_install_all(opts) do
    with  :ok <- ProjectHelper.phoenix_project?(),
          :ok <- perform_setup(opts),
          :ok <- ComponentManager.copy_all_components(opts[:no_rename])
    do
      IO.puts "\n\n🎊 Finished 🎊\n\n"
    else
      {:error, reason} -> IO.puts reason
    end
  end

  defp do_install(opts, component_names) do
    with  :ok <- ProjectHelper.phoenix_project?(),
          :ok <- maybe_perform_setup(opts),
          :ok <- ComponentManager.fetch_components(component_names, opts[:no_rename])
    do
      IO.puts get_finish_message(opts, component_names)
    else
      {:error, reason} -> IO.puts reason
    end
  end

  defp maybe_perform_setup(opts) do
    if opts[:setup] do
      perform_setup(opts)
    else
      :ok
    end
  end

  defp perform_setup(opts) do
    with  :ok <- ConfigManager.copy_petals_css(),
          :ok <- ConfigManager.update_css_imports(),
          :ok <- maybe_add_alpine_js(opts),
          :ok <- maybe_update_tailwind_config(opts),
          {:ok, _} <- FileManager.create_petal_components_folder(),
          :ok <- ComponentManager.copy_specific_component("helpers", opts[:no_rename])
    do
          :ok
    else
          {:error, reason} -> IO.puts reason
    end
  end

  defp maybe_add_alpine_js(opts) do
    if opts[:no_alpine], do: :ok, else: ConfigManager.add_alpine_js()
  end

  defp maybe_update_tailwind_config(opts) do
    if opts[:no_tailwind_config], do: :ok, else: ConfigManager.update_tailwind_config()
  end

  def get_finish_message(opts, component_names) do
    setup_string = if opts[:setup], do: "Setup ", else: ""
    component_string = if Enum.empty?(component_names), do: "", else: "\nAdded #{component_names}"

    "\n\n🎊 Finished #{setup_string}🎊#{component_string}\n\n"
  end

  defp print_help do
    IO.puts """
    Usage: mix petal.install [options] [component names]

    Options:
      --install-all, -a     Setup & install all components
      --setup, -s           Perform setup without installing components
      --list, -l            List available components
      --help, -h            Print this help message
      --no-alpine           Skip adding Alpine.js
      --no-rename           Skip renaming components (keep original namespaces)
      --no-tailwind-config  Skip updating Tailwind configuration

    Examples:
      mix petal.install --install-all
      mix petal.install --setup
      mix petal.install avatar menu
      mix petal.install --setup --no-alpine avatar menu
    """
  end

  defp list_components do
    Enum.each(Constants.components(), &IO.puts/1)
  end
end
