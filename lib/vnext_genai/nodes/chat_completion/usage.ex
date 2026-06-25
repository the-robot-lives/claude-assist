defmodule GenAI.ChatCompletion.Usage do
  defstruct prompt_tokens: nil,
            total_tokens: nil,
            completion_tokens: nil
  
  def new(options)
  def new(options) when is_struct(options) do
    new(Map.from_struct(options))
  end
  def new(options) do
    keys =
      __MODULE__.__info__(:struct)
      |> Enum.map(& &1.field)
      |> MapSet.new()

    options
    |> Enum.to_list()
    |> Enum.filter(&MapSet.member?(keys, elem(&1, 0)))
    |> __struct__()
  end
end
