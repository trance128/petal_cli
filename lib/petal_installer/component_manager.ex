defmodule PetalInstaller.ComponentManager do
  alias   PetalInstaller.{FileManager, Constants}

  def copy_all_components do
    FileManager.get_copy_all_component_paths()
    |> FileManager.recursive_copy()
  end


  def fetch_components([]) do
    IO.puts "Specify component names or use --list to see available components"
  end

  def fetch_components(component_names) do
    res = Enum.map(component_names, &fetch_component(&1))

    if Enum.any?(res, &match?({:error, _}, &1)) do
      Enum.each(res, fn
          {:error, reason}  -> IO.puts reason
          _                 -> nil
      end)

      IO.puts "\nTask Finished\n"
    else
      IO.puts "\n\n🎊 Finished fetching #{component_names} 🎊\n\n"
    end
  end

  ### Will also fetch any dependencies if they don't already exist in users' project
  def copy_specific_component(component_name) do
    {source_path, to_path} = FileManager.get_component_paths(component_name)

    if FileManager.exists?(to_path) do
      IO.puts("The file for #{IO.ANSI.bright()}#{IO.ANSI.yellow()}#{component_name}#{IO.ANSI.reset()} already exists at #{IO.ANSI.bright()}#{IO.ANSI.yellow}#{to_path}#{IO.ANSI.reset()}.")
      response = IO.gets("Overwrite?  (y/n):  ") |> String.trim() |> String.downcase()

      case response do
        "y" -> cont_copy_component(source_path, to_path, component_name)
        _   ->
          IO.puts("Skipping #{component_name}")
          :ok
      end

    else
      cont_copy_component(source_path, to_path, component_name)
    end
  end

  defp fetch_component(name) do
    cond do
      name == "icon"                   ->
          handle_icon_component()
      Enum.member?(Constants.components(), name)  ->
          copy_specific_component(name)
      true                             ->
          {:error, "Component #{name} not found"}
    end
  end

  defp cont_copy_component(source_path, to_path, component_name) do
    extract_and_get_dependencies(source_path)
    FileManager.copy(source_path, to_path, "Error copying component #{component_name}")
  end

  ### Checks for any component dependencies, and installs them if not present
  defp extract_and_get_dependencies(source_path) do
    content = FileManager.read!(source_path)

    dependencies = extract_dependencies(content)
    Enum.each(dependencies, fn dep ->
      handle_component_dependency(dep)
    end)
  end

  ### Similar to copy_specific_component, except doesn't ask the user to overwrite files
  ### if user already has the file, no overwrite occurs
  defp handle_component_dependency(component_name) do
    {source_path, target_path} = FileManager.get_component_paths(component_name)

    if not FileManager.exists?(target_path) do
      extract_and_get_dependencies(source_path)

      FileManager.copy(source_path, target_path, "Error copying component #{component_name}")
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

  defp handle_icon_component() do
    with  :ok <- copy_specific_component("icon"),
          :ok <- copy_icon_folder()
    do
          :ok
    end
  end

  defp copy_icon_folder() do
    FileManager.get_component_paths("icons")
    |> FileManager.recursive_copy()
  end
end
