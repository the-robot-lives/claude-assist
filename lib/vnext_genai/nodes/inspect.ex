defimpl Inspect,
  for: [
    GenAI.Tool,
    GenAI.Setting,
    GenAI.Setting.ModelSetting,
    GenAI.Setting.ProviderSetting,
    GenAI.Setting.SafetySetting,
    GenAI.Model,
    GenAI.Message,
    GenAI.Message.ToolResponse,
    GenAI.Message.ToolUsage,
    GenAI.ChatCompletion,
    GenAI.VNext.Graph
  ] do
  #import Inspect.Algebra

  def inspect(%{__struct__: module} = subject, opts) do
    limit =
      cond do
        opts.limit == :infinity -> :infinity
        opts.limit > 500 -> :high
        opts.limit < 250 -> :medium
        :else -> :low
      end

    case limit do
      :infinity ->
        # Show the full object
        module.inspect_full_detail(subject, opts)

      :low ->
        # Show id, name, description, and counts of inbound/outbound links
        module.inspect_low_detail(subject, opts)

      :medium ->
        # Show parameters with truncated values
        module.inspect_medium_detail(subject, opts)

      :high ->
        # Show inbound and outbound links with target/source ids
        module.inspect_high_detail(subject, opts)
    end
  end
end


defimpl Inspect,
        for: [
          GenAI.Graph.Link
        ] do
  #import Inspect.Algebra
  require GenAI.Records.Link
  
  def inspect(%{__struct__: _module} = subject, opts) do
    limit =
      cond do
        opts.limit == :infinity -> :infinity
        opts.limit > 500 -> :high
        opts.limit < 250 -> :medium
        :else -> :low
      end
    
    case limit do
      :infinity ->
        # Show the full object
        Inspect.Algebra.to_doc(Map.from_struct(subject), opts)
      
      _ ->
      
      with %GenAI.Graph.Link{
             source: GenAI.Records.Link.connector(node: source, socket: source_socket),
             target: GenAI.Records.Link.connector(node: target, socket: target_socket)
           } <- subject do
        Inspect.Algebra.concat(
          [
            "#GenAI.Graph.Link<",
            Inspect.Algebra.to_doc(source, opts),
            " [", Inspect.Algebra.to_doc(source_socket, opts), "]",
            "-->",
            "[", Inspect.Algebra.to_doc(target_socket, opts), "] ",
            Inspect.Algebra.to_doc(target, opts),
            "> "
          ])
        else
        _ -> Inspect.Algebra.concat(["#GenAI.Graph.Link<",">"])
      end
    end
  end
end


