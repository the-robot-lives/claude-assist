defmodule Timely.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Timely.Repo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Timely.DataCase
    end
  end

  setup tags do
    Timely.DataCase.setup_sandbox(tags)
    :ok
  end

  # ⟦𓆐𓆬𓆄𓄀⟧ setup_sandbox :: auto-generated pointer for public function setup_sandbox
  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Timely.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end
end
