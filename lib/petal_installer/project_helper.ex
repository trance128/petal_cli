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
    case FileManager.read("mix.exs") do
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
end
