defmodule GenAI.Document.ContentBlock do
  @vsn 1.0


  defstruct [
    content: [],
    meta: nil,
    vsn: @vsn,
  ]

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
