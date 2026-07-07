defmodule TheRobotRemembers.Postgrex.Agtype do
  @moduledoc """
  Passthrough Postgrex extension for Apache AGE's `agtype`.

  Without an agtype decoder in the Repo's types module, *any* query returning an `agtype` column
  fails at the prepare/describe stage — even a 0-row `CREATE`/`DELETE` — because Postgrex cannot
  describe the result column type. That is exactly what breaks a live AGE round-trip when the
  cypher isn't hand-cast to `::text`.

  This decodes `agtype` as its **text representation** (a plain string): agtype scalars come back
  JSON-quoted (`"uuid"`, numbers as-is), and vertices/edges/paths as AGE's text form — callers parse
  as needed (`GraphStore.AGE`, `GraphMirror`, the bench). Encoding is a passthrough for completeness;
  the app never binds an agtype parameter (all values are interpolated into the cypher string).

  Inert when AGE is not installed: the `agtype` type simply won't exist in `pg_type`, so this
  extension matches nothing and has no effect on ordinary databases.
  """
  @behaviour Postgrex.Extension
  import Postgrex.BinaryUtils, warn: false

  def init(_opts), do: nil

  def matching(_state), do: [type: "agtype"]

  def format(_state), do: :text

  def encode(_state) do
    quote location: :keep do
      value when is_binary(value) -> [<<byte_size(value)::int32()>> | value]
    end
  end

  def decode(_state) do
    quote location: :keep do
      <<len::int32(), value::binary-size(len)>> -> value
    end
  end
end
