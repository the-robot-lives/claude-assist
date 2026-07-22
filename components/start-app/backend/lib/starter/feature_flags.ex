defmodule Starter.FeatureFlags do
  # ⟦𓄋𓉥𓆷𓈥⟧ enabled? :: auto-generated pointer for public function enabled?
  def enabled?(flag) when is_atom(flag) do
    flags = Application.get_env(:starter, :feature_flags, %{})
    Map.get(flags, flag, false)
  end

  # ⟦𓃡𓅜𓋧𓄁⟧ all :: auto-generated pointer for public function all
  def all do
    Application.get_env(:starter, :feature_flags, %{})
    |> Enum.filter(fn {_k, v} -> v end)
    |> Enum.map(fn {k, _v} -> Atom.to_string(k) end)
  end
end
