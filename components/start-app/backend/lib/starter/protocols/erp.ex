require Protocol
Protocol.derive(Jason.Encoder, Noizu.Entity.TimeStamp, [])

defimpl Jason.Encoder, for: Tuple do
  def encode({:ref, _, _} = s, opts) do
    with {:ok, sref} <- Noizu.EntityReference.Protocol.sref(s) do
      sref
      |> encode_string(opts)
    else
      {:error, _} -> {:error, :invalid_sref}
    end
  end

  def encode(s, opts) do
    "#{inspect(s)}"
    |> encode_string(opts)
  end

  defp encode_string(value, {escape, encode_map, _user_settings}) do
    Jason.Encode.string(value, {escape, encode_map})
  end

  defp encode_string(value, opts) do
    Jason.Encode.string(value, opts)
  end
end

defimpl Noizu.EntityReference.Protocol, for: BitString do
  def handlers() do
    Starter.EntityRepo.sref_handlers()
  end

  def handler("ref." <> _ = sref) do
    with [_, h] <- Regex.run(~r/^ref.([^.]*)/, sref) do
      h = handlers()[h]
      (h && {:ok, h}) || {:error, {:handler_not_found, sref}}
    else
      _ -> {:error, {:handler_not_found, sref}}
    end
  end

  def handler(sref), do: {:error, {:handler_not_found, sref}}

  def id(subject) do
    with {:ok, handler} <- handler(subject) do
      apply(handler, :id, [subject])
    end
  end

  def kind(subject) do
    with {:ok, handler} <- handler(subject) do
      apply(handler, :kind, [subject])
    end
  end

  def ref(subject) do
    with {:ok, handler} <- handler(subject) do
      apply(handler, :ref, [subject])
    end
  end

  def sref(subject) do
    with {:ok, handler} <- handler(subject) do
      apply(handler, :sref, [subject])
    end
  end

  def entity(subject, context) do
    with {:ok, handler} <- handler(subject) do
      apply(handler, :entity, [subject, context])
    end
  end
end
