defmodule Mix.Tasks.Data.Import do
  use Mix.Task

  @shortdoc "Imports production database dump from the specified path"
  def run(path) do
    hostname = Application.fetch_env!(:helheim, Helheim.Repo)[:hostname]
    username = Application.fetch_env!(:helheim, Helheim.Repo)[:username]
    database = Application.fetch_env!(:helheim, Helheim.Repo)[:database]
    Mix.shell.cmd "pg_restore --verbose --clean --no-acl --no-owner -j 2 -h #{hostname} -U #{username} -d #{database} #{path}"
  end
end
