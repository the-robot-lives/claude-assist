defmodule GenAI.ChatCompletion do
  @moduledoc """
  Encodes a LLM ChatCompletion response.
  """
  @vsn 1.0

  use GenAI.Graph.NodeBehaviour
  @derive GenAI.Graph.NodeProtocol
  # @derive GenAI.Thread.SessionProtocol

  defnodestruct(
    model: nil,
    provider: nil,
    seed: nil,
    choices: nil,
    usage: nil,
    details: nil
  )

  defnodetype(
    model: term,
    provider: term,
    seed: term,
    choices: term,
    usage: term,
    details: term
  )
  
  def inspect_custom_details(subject, opts) do
    [
      "model:", Inspect.Algebra.to_doc(subject.model, opts), ", ",
      "seed:", Inspect.Algebra.to_doc(subject.seed, opts), ", ",
      "choices:", Inspect.Algebra.to_doc(subject.choices, opts), ", ",
      "usage:", Inspect.Algebra.to_doc(subject.usage, opts), ", ",
    ]
  end
  
  
  def from_json(options)
  def from_json(options) when is_struct(options) do
    from_json(Map.from_struct(options))
  end
  def from_json(options) do
    keys =
      __MODULE__.__info__(:struct)
      |> Enum.map(& &1.field)
      |> MapSet.new()

    details =
      options
      |> Enum.to_list()
      |> Enum.filter(&(!MapSet.member?(keys, elem(&1, 0))))
      |> Enum.into(%{})

    option_details =
      (options[:details] || %{})
      |> Enum.into(%{})

    details = Map.merge(details, option_details)

    options
    |> put_in([:details], details)
    |> new()
  end
end
