defmodule TheRobotRemembers.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias TheRobotRemembers.Repo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import TheRobotRemembers.DataCase
    end
  end

  setup tags do
    TheRobotRemembers.DataCase.setup_sandbox(tags)
    :ok
  end

  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(TheRobotRemembers.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end
end
