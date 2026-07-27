defmodule Timely.WireRecorder do
  @moduledoc """
  Records real HTTP request/response pairs into `wire-fixtures.json`.

  Everything here exists to make one guarantee: the fixture file is a
  transcript of what the server **actually emitted**, never a description of
  what someone believed it emits. Cases are captured by driving the real router
  through `Phoenix.ConnTest` and reading the serialized response body back off
  the conn, so a fixture cannot drift from the implementation without the
  drift-guard test failing.

  Two problems have to be solved to make that transcript committable:

  ## Determinism

  Real output contains generated uuids and wall-clock timestamps, which differ
  on every run and would make the file unstable. They are replaced with
  placeholders **in place** - `@workspace_id`, `@timestamp` - so the shape of
  the payload survives intact.

  ## Presence is the payload

  Normalization never removes a key. It cannot: the single most important case
  in this file is the difference between `"end": null` and `end` absent, and a
  normalizer that dropped nulls or collapsed empty values would erase exactly
  the distinction the fixture exists to pin.
  """

  import Phoenix.ConnTest

  @endpoint TimelyWeb.Endpoint

  @uuid_pattern ~r/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/
  @timestamp_pattern ~r/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})$/
  @jwt_pattern ~r/^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$/
  @sso_code_pattern ~r/^[A-Za-z0-9_-]{43}$/

  # Keys that lead in every object, in this order; everything else follows
  # alphabetically. Alphabetical alone would be deterministic but would bury
  # `id` and `name` in the middle of a case, and this file is read by humans as
  # well as by test suites.
  @key_order ~w(
    $schema_note title version generated_for_contract_version about
    how_to_consume normalization placeholders traps groups cases
    id group name trap note request response
    method path query headers body status
  )

  @doc "Starts the per-run recorder."
  # ⟦𓂋𓎡𓂋𓂧⟧ start :: Starts the fixture recorder for one run.
  def start do
    {:ok, pid} = Agent.start_link(fn -> %{cases: [], labels: %{}} end)
    Process.put(__MODULE__, pid)
    :ok
  end

  defp agent, do: Process.get(__MODULE__)

  @doc """
  Names a uuid so it renders as a readable placeholder, and returns it
  unchanged so call sites read as `ws = label(workspace!(), "workspace_id")`.

  Labelling is what keeps *relationships* visible after normalization: the same
  id appearing in a request and in the response it produced renders as the same
  placeholder, so a reader can still see that a mutation's `payload.id` came
  back as the entity's `id`.
  """
  # ⟦𓃭𓃀𓋴𓈖⟧ label :: Names a uuid for readable, relationship-preserving output.
  def label(uuid, name) do
    Agent.update(agent(), fn state ->
      %{state | labels: Map.put(state.labels, uuid, "@" <> name)}
    end)

    uuid
  end

  @doc """
  Performs a request against the real router and records it.

  `opts[:headers]` are recorded verbatim (the bearer token is never among them);
  `opts[:query]` is recorded separately from the path so a client can see the
  parameters without parsing a URL.
  """
  # ⟦𓂋𓎡𓂧𓋴⟧ record :: Performs a real request and records the pair.
  def record(conn, attrs, opts \\ []) do
    method = Keyword.fetch!(opts, :method)
    path = Keyword.fetch!(opts, :path)
    query = Keyword.get(opts, :query, %{})
    headers = Keyword.get(opts, :headers, %{})
    body = Keyword.get(opts, :body)

    raw_body = Keyword.get(opts, :raw_body)

    conn =
      Enum.reduce(headers, conn, fn {name, value}, acc ->
        Plug.Conn.put_req_header(acc, name, value)
      end)

    # The body is sent as encoded JSON bytes with an explicit content type, so
    # it travels through the endpoint's real Plug.Parsers exactly as a client's
    # bytes would. Handing `Phoenix.ConnTest` a bare map would inject it into
    # `conn.params` and bypass the parser - and with it the only thing that
    # decides whether `"end": null` arrives as nil or as nothing at all, which
    # is the distinction these fixtures exist to pin.
    {conn, payload} =
      cond do
        raw_body != nil -> {conn, raw_body}
        body != nil -> {json_conn(conn), Jason.encode!(body)}
        true -> {conn, ""}
      end

    full_path = if query == %{}, do: path, else: path <> "?" <> URI.encode_query(query)

    result =
      case method do
        "GET" -> get(conn, full_path)
        "POST" -> post(conn, full_path, payload)
        "PATCH" -> patch(conn, full_path, payload)
      end

    response = decode_response(result)

    entry =
      attrs
      |> Map.put("request", compact(%{
        "method" => method,
        "path" => path,
        "query" => if(query == %{}, do: nil, else: stringify(query)),
        "headers" => if(headers == %{}, do: nil, else: headers),
        "body" => body
      }))
      |> Map.put("response", response)

    Agent.update(agent(), fn state -> %{state | cases: state.cases ++ [entry]} end)

    result
  end

  # A binary body is recorded by its content type and length rather than its
  # bytes: the fixture pins that the server returns image bytes with the right
  # header, and embedding a PNG in a JSON contract file helps nobody.
  defp decode_response(conn) do
    content_type =
      conn
      |> Plug.Conn.get_resp_header("content-type")
      |> List.first()
      |> to_string()
      |> String.split(";")
      |> List.first()

    cond do
      # A redirect's payload IS its Location header - for the SSO flow that
      # header is the entire contract, since it decides whether a native
      # authentication session ever regains control.
      conn.status in 300..399 ->
        %{
          "status" => conn.status,
          "location" => conn |> Plug.Conn.get_resp_header("location") |> List.first()
        }

      content_type == "application/json" ->
        %{"status" => conn.status, "body" => Jason.decode!(conn.resp_body)}

      true ->
        %{
          "status" => conn.status,
          "content_type" => content_type,
          "body_byte_size" => byte_size(conn.resp_body)
        }
    end
  end

  @doc "Every recorded case, normalized."
  # ⟦𓎡𓋴𓋴𓈖⟧ cases :: The recorded cases, normalized.
  def cases do
    %{cases: cases, labels: labels} = Agent.get(agent(), & &1)
    normalize(cases, labels)
  end

  @doc "The placeholder table, for the fixture header."
  # ⟦𓊪𓃭𓋴𓏏⟧ placeholders :: The placeholder legend for the header.
  def placeholders do
    Agent.get(agent(), & &1).labels
    |> Map.values()
    |> Enum.uniq()
    |> Enum.sort()
  end

  @doc """
  Replaces generated ids and wall-clock times with placeholders, **without ever
  removing a key**.
  """
  # ⟦𓈖𓂋𓅓𓋴⟧ normalize :: Replaces nondeterministic values with placeholders.
  def normalize(value, labels) when is_map(value) do
    Map.new(value, fn {k, v} -> {k, normalize(v, labels)} end)
  end

  def normalize(value, labels) when is_list(value) do
    Enum.map(value, &normalize(&1, labels))
  end

  def normalize(value, labels) when is_binary(value) do
    cond do
      # A bare uuid: a labelled one keeps its relationship, an incidental one
      # (a server-minted id the scenario never named) becomes a generic marker.
      Map.has_key?(labels, value) ->
        Map.fetch!(labels, value)

      Regex.match?(~r/^#{@uuid_pattern.source}$/, value) ->
        "@uuid"

      Regex.match?(@timestamp_pattern, value) ->
        "@timestamp"

      # Signed tokens are freshly minted on every run. Their VALUE is never part
      # of a contract, but their presence and field name are, so the key is kept
      # and only the bearer material is replaced.
      Regex.match?(@jwt_pattern, value) ->
        "@jwt"

      # The one-time SSO code is 32 random bytes and equally unstable.
      Regex.match?(@sso_code_pattern, value) ->
        "@sso_code"

      # A uuid embedded in a larger string, e.g. `blob_url`. The surrounding
      # shape is part of the contract, so only the id is substituted.
      Regex.match?(@uuid_pattern, value) ->
        Regex.replace(@uuid_pattern, value, fn match ->
          Map.get(labels, match, "@uuid")
        end)

      true ->
        value
    end
  end

  def normalize(value, _labels), do: value

  @doc """
  Encodes the document as stable, human-readable JSON.

  Key order is fixed rather than left to map iteration order, because
  byte-identical regeneration is the property that lets the drift guard compare
  the committed file to a fresh capture with `==`.
  """
  # ⟦𓆑𓈖𓎡𓂧⟧ encode :: Byte-stable pretty JSON encoding.
  def encode(value), do: IO.iodata_to_binary([do_encode(value, 0), "\n"])

  defp do_encode(map, _depth) when is_map(map) and map_size(map) == 0, do: "{}"

  defp do_encode(map, depth) when is_map(map) do
    pad = String.duplicate("  ", depth + 1)
    close = String.duplicate("  ", depth)

    body =
      map
      |> Map.keys()
      |> sort_keys()
      |> Enum.map(fn key ->
        [pad, Jason.encode!(to_string(key)), ": ", do_encode(Map.fetch!(map, key), depth + 1)]
      end)
      |> Enum.intersperse(",\n")

    ["{\n", body, "\n", close, "}"]
  end

  defp do_encode([], _depth), do: "[]"

  defp do_encode(list, depth) when is_list(list) do
    pad = String.duplicate("  ", depth + 1)
    close = String.duplicate("  ", depth)

    body =
      list
      |> Enum.map(fn item -> [pad, do_encode(item, depth + 1)] end)
      |> Enum.intersperse(",\n")

    ["[\n", body, "\n", close, "]"]
  end

  defp do_encode(nil, _depth), do: "null"
  defp do_encode(true, _depth), do: "true"
  defp do_encode(false, _depth), do: "false"
  defp do_encode(value, _depth) when is_integer(value), do: Integer.to_string(value)
  defp do_encode(value, _depth) when is_float(value), do: Jason.encode!(value)
  defp do_encode(value, _depth) when is_binary(value), do: Jason.encode!(value)
  defp do_encode(value, _depth) when is_atom(value), do: Jason.encode!(to_string(value))

  defp sort_keys(keys) do
    Enum.sort_by(keys, fn key ->
      key = to_string(key)

      case Enum.find_index(@key_order, &(&1 == key)) do
        nil -> {1, key}
        index -> {0, index}
      end
    end)
  end

  defp json_conn(conn) do
    if Plug.Conn.get_req_header(conn, "content-type") == [],
      do: Plug.Conn.put_req_header(conn, "content-type", "application/json"),
      else: conn
  end

  defp compact(map) do
    map
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end

  defp stringify(map), do: Map.new(map, fn {k, v} -> {to_string(k), to_string(v)} end)
end
