defmodule PetalInstaller.FileManager do
  @salad :salad
  @petal :petal

  @package_name :petal_cli

  @doc """
    Saves the project name into FileManager process
  """
  @spec set_project_name(String.t()) :: :ok
  def set_project_name(project_name) do
    Process.put(:project_name, project_name)
    :ok
  end

  @doc """
    Copies a single file
  """
  def copy(source_path, dest_path, error_message \\ "Failed to copy files") do
    case File.cp(source_path, dest_path) do
      :ok ->
        :ok
      {:error, reason} ->
        {:error, "#{error_message}: #{reason}"}
    end
  end

  @doc """
    Recursively copies all files from source_path into dest_path
  """
  @spec recursive_copy({binary(), binary()}) :: :ok | {:error, String.t()}
  def recursive_copy({source_path, dest_path}) do
    case File.cp_r(source_path, dest_path) do
      {:ok, _}            ->
          :ok
      {:error, reason, _} ->
          {:error, "Failed to copy files: #{reason}"}
    end
  end

  @doc """
    Creates the petal component folder in users' lib/[project_name]_web/components/
  """
  @spec create_component_folder(atom()) :: {:ok, Path.t()} | {:error, String.t()}
  def create_component_folder(framework) do
    folder_name =
      case framework do
        :petal       -> "petal_components"
        :salad       -> "salad_ui"
      end

    project_name = Process.get(:project_name)
    file_path = Path.join(["lib", "#{project_name}_web", "components", folder_name])

    case File.mkdir(file_path) do
      :ok               -> {:ok, file_path}
      {:error, reason}  -> {:error, reason}
    end
  end

  def get_web_namespace do
    Process.get(:project_name)
    |> Atom.to_string()
    |> Macro.camelize()
    |> Kernel.<>("Web")
  end


  @doc """
    Gets paths for specified component, in the form {source_path, dest_path}
  """
  @spec get_component_paths(String.t()) :: {binary(), binary()}
  def get_component_paths(component_name) do
    project_name = Process.get(:project_name)

    {
      # source_path
      Path.join(["deps", "petal_components", "lib", "petal_components", "#{component_name}.ex"]),
      # dest_path
      Path.join(["lib", "#{project_name}_web", "components", "petal_components", "#{component_name}.ex"])
    }
  end

  @doc """
    Returns the paths required for copying all components

    returns {source_path, dest_path} tuple
  """
  @spec get_copy_all_component_paths(atom()) :: {binary(), binary()}
  def get_copy_all_component_paths(framework) do
    project_name = Process.get(:project_name)

    source_path =
      case framework do
        :petal -> Path.join(["deps", "petal_components",  "lib"])
        :salad -> Path.join(["deps", "salad_ui",          "lib"]);
      end
    dest_path     = Path.join(["lib", "#{project_name}_web", "components"])

    {source_path, dest_path}
  end

  @doc """
    Gets the requested source and dest paths depending on framework
    and which paths we need

    returns path | {source_path, dest_path}
  """
  @spec get_paths(atom()) :: Path.t() | {Path.t(), Path.t()}
  def get_paths(:app_css) do
    Path.join(["assets", "css", "app.css"])
  end
  def get_paths(:root_layout) do
    project_name = Process.get(:project_name)
    Path.join(["lib", "#{project_name}_web", "components", "layouts", "root.html.heex"])
  end
  def get_paths(:tailwind_config) do
    Path.join(["assets", "tailwind.config.js"])
  end
  def get_paths(:tailwind_animate) do
    {
      # source_path
      Path.join(["deps", @package_name, "assets", "tailwindcss-animate.js"]),
      # dest_path
      Path.join(["assets", "js", "tailwindcss-animate.js"])
    }
  end

  @spec get_paths(atom(), atom()) :: {Path.t(), Path.t()}
  def get_paths(@salad, :css) do
    {
      # source_path
      Path.join(["deps", "salad_ui", "assets", "salad_ui.css"]),
      # dest_path
      Path.join(["assets", "css", "salad_ui.css"])
    }
  end
  def get_paths(@petal, :css) do
    {
      # source_path
      Path.join(["deps", "petal_components", "assets", "default.css"]),
      # dest_path
      Path.join(["assets", "css", "petals_default.css"])
    }
  end

  @doc """
    Same as File.exists?/1
  """
  @spec exists?(Path.t()) :: boolean()
  def exists?(path) do
    File.exists?(path)
  end

  @doc """
    Same as File.read/1
  """
  def read(path) do
    File.read(path)
  end

  @doc """
    Same as File.read!/1
  """
  @spec read!(Path.t()) :: binary()
  def read!(path) do
    File.read!(path)
  end

  def write(path, content) do
    File.write(path, content)
  end

  def ls!(path) do
    File.ls!(path)
  end

  def mkdir(path) do
    File.mkdir(path)
  end
end
