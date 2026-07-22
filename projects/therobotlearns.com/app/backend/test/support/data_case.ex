defmodule TheRobotLearns.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias TheRobotLearns.Repo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import TheRobotLearns.DataCase
    end
  end

  setup tags do
    TheRobotLearns.DataCase.setup_sandbox(tags)
    :ok
  end

  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(TheRobotLearns.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end
end
