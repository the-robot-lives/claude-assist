defmodule Foryou.Lists do
  @moduledoc """
  Context for Lists + their typed Attributes (the no-migration field model).

  A List is a named signup collection under a Service (project). Attributes are
  declared per-list with a type but no schema migration; their submitted values
  live on `signups.attribs`. `validate_attributes/2` is the server-authoritative
  validator every signup path runs (public endpoint, dual-write, import): it
  type-checks, enforces required/validation rules, drops unknown fields, and
  surfaces the identity email.

  Style mirrors `Foryou.Forms` / `Foryou.Inquiries`.
  """
  import Ecto.Query
  alias Foryou.Repo
  alias Foryou.Schema.Lists.{List, ListAttribute}

  @email_regex ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/
  @uuid_regex ~r/^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/

  # ── Reads ──────────────────────────────────────────────────────

  def list_lists(project_id) do
    from(l in List,
      where: l.project_id == ^project_id and l.status == "active",
      order_by: l.inserted_at
    )
    |> Repo.all()
  end

  def get_list(id), do: Repo.get(List, id)

  def get_by_slug(project_id, slug) do
    Repo.get_by(List, project_id: project_id, slug: slug)
  end

  def get_by_public_slug(public_slug), do: Repo.get_by(List, public_slug: public_slug)

  @doc """
  Best-effort resolution of a list by `(service_slug, list_slug)` — the alias
  path. `(project.slug, list.slug)` is not globally unique (D13), so this returns
  the first match; the canonical public key is `public_slug`.
  """
  def get_by_service_slugs(service_slug, list_slug) do
    from(l in List,
      join: p in Foryou.Schema.Projects.Project,
      on: p.id == l.project_id,
      where: p.slug == ^service_slug and l.slug == ^list_slug,
      limit: 1
    )
    |> Repo.one()
  end

  @doc "Active attributes for a list, ordered for form rendering."
  def list_attributes(list_id) do
    from(a in ListAttribute,
      where: a.list_id == ^list_id and a.status == "active",
      order_by: [asc: a.sort_order, asc: a.inserted_at]
    )
    |> Repo.all()
  end

  def get_attribute(id), do: Repo.get(ListAttribute, id)

  # ── List writes ────────────────────────────────────────────────

  def create_list(project_id, attrs) do
    attrs = attrs |> stringify() |> Map.put("project_id", project_id)
    %List{} |> List.changeset(attrs) |> Repo.insert()
  end

  def update_list(%List{} = list, attrs) do
    list |> List.changeset(stringify(attrs)) |> Repo.update()
  end

  def archive_list(%List{} = list), do: update_list(list, %{"status" => "archived"})
  def restore_list(%List{} = list), do: update_list(list, %{"status" => "active"})

  # ── Attribute writes (no-migration declaration) ────────────────

  def declare_attribute(%List{} = list, attrs) do
    attrs = attrs |> stringify() |> Map.put("list_id", list.id)
    %ListAttribute{} |> ListAttribute.changeset(attrs) |> Repo.insert()
  end

  def update_attribute(%ListAttribute{} = attr, attrs) do
    attr |> ListAttribute.changeset(stringify(attrs)) |> Repo.update()
  end

  @doc "Idempotent upsert of an attribute by (list_id, slug) — the TF-provider surface."
  def upsert_attribute(%List{} = list, %{} = attrs) do
    attrs = stringify(attrs)

    case attrs["slug"] && Repo.get_by(ListAttribute, list_id: list.id, slug: attrs["slug"]) do
      %ListAttribute{} = existing -> update_attribute(existing, attrs)
      _ -> declare_attribute(list, attrs)
    end
  end

  @doc "Rewrite sort_order to the given slug order."
  def reorder_attributes(%List{} = list, ordered_slugs) when is_list(ordered_slugs) do
    ordered_slugs
    |> Enum.with_index()
    |> Enum.each(fn {slug, idx} ->
      from(a in ListAttribute, where: a.list_id == ^list.id and a.slug == ^slug)
      |> Repo.update_all(set: [sort_order: idx, updated_at: DateTime.utc_now()])
    end)

    :ok
  end

  def deprecate_attribute(%ListAttribute{} = attr) do
    update_attribute(attr, %{"status" => "deprecated"})
  end

  # ── Validation (server-authoritative) ──────────────────────────

  @doc """
  Validate submitted values against the list's active attributes.

  Returns `{:ok, normalized}` where `normalized` is a map of `slug => coerced
  value` for known attributes only (unknown fields dropped, US-039), or
  `{:error, field_errors}` mapping attribute slug => message.
  """
  @spec validate_attributes(List.t(), map()) :: {:ok, map()} | {:error, map()}
  def validate_attributes(%List{} = list, values) when is_map(values) do
    values = stringify(values)
    attributes = list_attributes(list.id)

    {normalized, errors} =
      Enum.reduce(attributes, {%{}, %{}}, fn attr, {acc, errs} ->
        raw = Map.get(values, attr.slug)

        case validate_one(attr, raw) do
          :skip -> {acc, errs}
          {:ok, coerced} -> {Map.put(acc, attr.slug, coerced), errs}
          {:error, msg} -> {acc, Map.put(errs, attr.slug, msg)}
        end
      end)

    if errors == %{}, do: {:ok, normalized}, else: {:error, errors}
  end

  @doc """
  The identity email for a normalized value map — the value of the list's
  `is_identity` email attribute, falling back to a plain `email` key. Returns nil
  when no email is resolvable.
  """
  def identity_email(%List{} = list, normalized) do
    identity_slug =
      list.id
      |> list_attributes()
      |> Enum.find_value(fn a -> a.is_identity && a.slug end)

    email = (identity_slug && normalized[identity_slug]) || normalized["email"]
    email && email |> to_string() |> String.trim() |> String.downcase()
  end

  # blank + not required -> skip; blank + required -> error
  defp validate_one(%ListAttribute{required: required} = attr, raw) do
    cond do
      blank?(raw) and required -> {:error, "is required"}
      blank?(raw) -> :skip
      true -> coerce(attr, raw)
    end
  end

  defp coerce(%ListAttribute{type: "email"} = attr, raw) do
    v = raw |> to_string() |> String.trim()
    if Regex.match?(@email_regex, v), do: check_rules(attr, v), else: {:error, "is not a valid email"}
  end

  defp coerce(%ListAttribute{type: "string"} = attr, raw), do: check_rules(attr, to_string(raw))
  defp coerce(%ListAttribute{type: "text"} = attr, raw), do: check_rules(attr, to_string(raw))

  defp coerce(%ListAttribute{type: "int"} = attr, raw) do
    case cast_int(raw) do
      {:ok, n} -> check_rules(attr, n)
      :error -> {:error, "is not an integer"}
    end
  end

  defp coerce(%ListAttribute{type: "float"} = attr, raw) do
    case cast_float(raw) do
      {:ok, n} -> check_rules(attr, n)
      :error -> {:error, "is not a number"}
    end
  end

  defp coerce(%ListAttribute{type: "date"} = attr, raw) do
    case Date.from_iso8601(to_string(raw)) do
      {:ok, d} -> check_rules(attr, Date.to_iso8601(d))
      _ -> {:error, "is not an ISO-8601 date"}
    end
  end

  defp coerce(%ListAttribute{type: "guid"} = attr, raw) do
    v = to_string(raw)
    if Regex.match?(@uuid_regex, v), do: check_rules(attr, v), else: {:error, "is not a valid guid"}
  end

  defp coerce(%ListAttribute{type: "select"} = attr, raw) do
    v = to_string(raw)
    if v in option_values(attr), do: {:ok, v}, else: {:error, "is not an allowed option"}
  end

  defp coerce(%ListAttribute{type: "multiselect"} = attr, raw) do
    allowed = option_values(attr)
    list = if is_list(raw), do: Enum.map(raw, &to_string/1), else: [to_string(raw)]

    if Enum.all?(list, &(&1 in allowed)),
      do: {:ok, list},
      else: {:error, "contains a value that is not an allowed option"}
  end

  defp coerce(_attr, raw), do: {:ok, raw}

  # validation rules: length (string/text), min/max (int/float), pattern (string/guid)
  defp check_rules(%ListAttribute{validation: nil}, v), do: {:ok, v}

  defp check_rules(%ListAttribute{validation: rules}, v) when is_map(rules) do
    Enum.reduce_while(rules, {:ok, v}, fn
      {"length", max}, acc when is_binary(v) ->
        if String.length(v) <= max, do: {:cont, acc}, else: {:halt, {:error, "is too long"}}

      {"pattern", pattern}, acc when is_binary(v) ->
        case Regex.compile(pattern) do
          {:ok, re} -> if Regex.match?(re, v), do: {:cont, acc}, else: {:halt, {:error, "has an invalid format"}}
          _ -> {:cont, acc}
        end

      {"min", min}, acc when is_number(v) ->
        if v >= min, do: {:cont, acc}, else: {:halt, {:error, "is below the minimum"}}

      {"max", max}, acc when is_number(v) ->
        if v <= max, do: {:cont, acc}, else: {:halt, {:error, "is above the maximum"}}

      _, acc ->
        {:cont, acc}
    end)
  end

  defp check_rules(_attr, v), do: {:ok, v}

  defp option_values(%ListAttribute{options: options}) when is_list(options) do
    Enum.map(options, fn
      %{"value" => v} -> to_string(v)
      %{value: v} -> to_string(v)
      other -> to_string(other)
    end)
  end

  defp option_values(_), do: []

  defp cast_int(n) when is_integer(n), do: {:ok, n}

  defp cast_int(raw) when is_binary(raw) do
    case Integer.parse(String.trim(raw)) do
      {n, ""} -> {:ok, n}
      _ -> :error
    end
  end

  defp cast_int(_), do: :error

  defp cast_float(n) when is_number(n), do: {:ok, n * 1.0}

  defp cast_float(raw) when is_binary(raw) do
    case Float.parse(String.trim(raw)) do
      {n, ""} -> {:ok, n}
      _ -> :error
    end
  end

  defp cast_float(_), do: :error

  defp blank?(nil), do: true
  defp blank?(""), do: true
  defp blank?([]), do: true
  defp blank?(v) when is_binary(v), do: String.trim(v) == ""
  defp blank?(_), do: false

  defp stringify(map) do
    Map.new(map, fn {k, v} -> {to_string(k), v} end)
  end
end
