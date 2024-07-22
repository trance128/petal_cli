defmodule PetalInstaller.ProjectHelper do
  alias   PetalInstaller.FileManager

  def phoenix_project? do
    if do_phoenix_project?() do
      :ok
    else
      {:error, "Error: This doesn't appear to be a Phoenix project"}
    end
  end

  defp do_phoenix_project? do
    FileManager.exists?("mix.exs") &&
    FileManager.exists?("config/config.exs") &&
    FileManager.exists?("lib") &&
    FileManager.read!("mix.exs") =~ "phoenix"
  end

  def get_project_name do
    # Mix.Project.config()[:app]
    Mix.Project.get().project()[:app]
  end
end
