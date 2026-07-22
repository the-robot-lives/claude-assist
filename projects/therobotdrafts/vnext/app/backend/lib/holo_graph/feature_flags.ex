defmodule HoloGraph.FeatureFlags do
  def enabled?(flag) when is_atom(flag) do
    flags = Application.get_env(:holo_graph, :feature_flags, %{})
    Map.get(flags, flag, false)
  end

  def all do
    Application.get_env(:holo_graph, :feature_flags, %{})
    |> Enum.filter(fn {_k, v} -> v end)
    |> Enum.map(fn {k, _v} -> Atom.to_string(k) end)
  end
end
