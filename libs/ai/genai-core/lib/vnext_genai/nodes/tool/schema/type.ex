defmodule GenAI.Tool.Schema.Type do
  @moduledoc """
  Extract known schema types from JSON.



  """

  @schema_types [
    GenAI.Tool.Schema.Object,
    GenAI.Tool.Schema.Enum,
    GenAI.Tool.Schema.String,
    GenAI.Tool.Schema.Number,
    GenAI.Tool.Schema.Integer,
    GenAI.Tool.Schema.Null,
    GenAI.Tool.Schema.Bool
  ]

  # ⟦𓐠𓃠𓂑𓍣⟧ from_json :: auto-generated pointer for public function from_json
  def from_json(json) do
    @schema_types
    |> Enum.find_value({:error, :pending}, &((&1.is_type(json) && &1.from_json(json)) || nil))
  end
end
