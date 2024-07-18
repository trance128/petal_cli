defmodule PetalInstaller.FileManager do
  @component_source_path ["deps", "petal_components", "lib"]

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
  def copy(source_path, to_path, error_message \\ "Failed to copy files") do
    case File.cp(source_path, to_path) do
      :ok ->
        :ok
      {:error, reason} ->
        {:error, "#{error_message}: #{reason}"}
    end
  end

  @doc """
    Recursively copies all files from source_path into to_path
  """
  @spec recursive_copy({binary(), binary()}) :: :ok | {:error, String.t()}
  def recursive_copy({source_path, to_path}) do
    case File.cp_r(source_path, to_path) do
      {:ok, _}            ->
          :ok
      {:error, reason, _} ->
          {:error, "Failed to copy files: #{reason}"}
    end
  end

  @doc """
    Creates the petal component folder in users' lib/[project_name]_web/components/
  """
  @spec create_petal_components_folder() :: {:ok, Path.t()} | {:error, String.t()}
  def create_petal_components_folder do
    project_name = Process.get(:project_name)
    file_path = Path.join(["lib", "#{project_name}_web", "components", "petal_components"])

    case File.mkdir(file_path) do
      :ok               -> {:ok, file_path}
      {:error, reason}  -> {:error, reason}
    end
  end

  def get_web_namespace do
    Process.get(:project_name)
    |> Macro.camelize()
    |> Kernel.<>("Web")
  end


  @doc """
    Gets paths for specified component, in the form {source_path, to_path}
  """
  @spec get_component_paths(String.t()) :: {binary(), binary()}
  def get_component_paths(component_name) do
    project_name = Process.get(:project_name)

    {
      # source_path
      Path.join(@component_source_path ++ ["petal_components", "#{component_name}.ex"]),
      # to_path
      Path.join(["lib", "#{project_name}_web", "components", "petal_components", "#{component_name}.ex"])
    }
  end

  @doc """
    Returns the paths required for copying all components

    returns {source_path, to_path} tuple
  """
  @spec get_copy_all_component_paths() :: {binary(), binary()}
  def get_copy_all_component_paths do
    project_name = Process.get(:project_name)

    source_path = Path.join(@component_source_path)
    to_path     = Path.join(["lib", "#{project_name}_web", "components"])

    {source_path, to_path}
  end

  @doc """
    Gets the required paths for copying css files
    source_path = deps/petal_components/assets/defaults.css
    to_path     = assets/css/petals_default.css

    returns {source_path, to_path}
  """
  @spec get_css_paths() :: {Path.t(), Path.t()}
  def get_css_paths do
    {
      # source_path
      Path.join(["deps", "petal_components", "assets", "default.css"]),
      # to_path
      Path.join(["assets", "css", "petals_default.css"])
    }
  end

  @spec get_app_css_path() :: binary()
  def get_app_css_path() do
    Path.join(["assets", "css", "app.css"])
  end

  @spec get_root_layout_path() :: binary()
  def get_root_layout_path do
    project_name = Process.get(:project_name)
    Path.join(["lib", "#{project_name}_web", "components", "layouts", "root.html.heex"])
  end

  def get_tailwind_config_path do
    Path.join(["assets", "tailwind.config.js"])
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
