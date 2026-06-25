defimpl Jason.Encoder, for: [GenAI.Tool] do
  def encode(subject, opts) do
    %{
      name: subject.name,
      description: subject.description,
      parameters: subject.parameters
    }
    |> Jason.Encode.map(opts)
  end
end

defimpl Jason.Encoder,
  for: [
    GenAI.Tool.Schema.Bool,
    GenAI.Tool.Schema.Enum,
    GenAI.Tool.Schema.Integer,
    GenAI.Tool.Schema.Null,
    GenAI.Tool.Schema.Number,
    GenAI.Tool.Schema.Object,
    GenAI.Tool.Schema.String
  ] do
  @exclude [:vsn]

  def encode(subject, opts) do
    subject
    |> Map.from_struct()
    |> Enum.reject(fn {k, v} -> k in @exclude or is_nil(v) end)
    |> Enum.into(%{})
    |> Jason.Encode.map(opts)
  end
end
