defmodule TherobotplansWeb.PersonalItemController do
  @moduledoc """
  Personal todos (WS-A US-011). A personal item is an `items` row owned by a user
  (`owner_user_id`) and project-less (`project_id IS NULL`). Follows
  `ItemController`'s Authz + JSON conventions, PLUS an ownership guard: every
  action asserts the target item's `owner_user_id == current_user`. Personal
  items are strictly private to their owner — even org admins cannot list or edit
  another user's personal todos.
  """
  use TherobotplansWeb, :controller

  alias Therobotplans.Domains.Personal
  alias Therobotplans.Domains.Personal.Recurrence
  alias Therobotplans.Authz

  # GET /api/v1/organizations/:org_id/personal/items
  #   ?group=all|grouped (default grouped) &tag= &status= &q= &tz=
  def index(conn, %{"org_id" => org_id} = params) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, "viewer") do
      opts =
        []
        |> put_opt(:tag, split_tags(params["tag"]))
        |> put_opt(:status, params["status"])
        |> put_opt(:q, params["q"])
        |> put_opt(:tz, params["tz"])

      tz = params["tz"]
      today = Recurrence.today_in_zone(tz)

      case params["group"] do
        "all" ->
          items = Personal.list_items(org_id, user_id, opts)
          json(conn, %{items: Enum.map(items, &item_to_json(&1, today))})

        _ ->
          grouped = Personal.list_grouped(org_id, user_id, opts)

          json(conn, %{
            groups:
              Map.new(grouped, fn {bucket, items} ->
                {bucket, Enum.map(items, &item_to_json(&1, today))}
              end)
          })
      end
    else
      err -> handle_error(conn, err)
    end
  end

  # GET /api/v1/organizations/:org_id/personal/tags  — distinct tags (autocomplete)
  def tags(conn, %{"org_id" => org_id}) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, "viewer") do
      json(conn, %{tags: Personal.distinct_tags(org_id)})
    else
      err -> handle_error(conn, err)
    end
  end

  # POST /api/v1/organizations/:org_id/personal/items
  def create(conn, %{"org_id" => org_id, "item" => item_params}) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, "member") do
      attrs = %{
        title: item_params["title"],
        description: item_params["description"],
        item_type: item_params["item_type"] || "todo",
        status: item_params["status"] || "open",
        priority: item_params["priority"],
        due_date: resolve_due(item_params["due_date"], item_params["tz"]),
        tags: item_params["tags"] || [],
        recurrence: item_params["recurrence"]
      }

      case Personal.create_item(org_id, user_id, attrs) do
        {:ok, item} ->
          today = Recurrence.today_in_zone(item_params["tz"])
          conn |> put_status(:created) |> json(%{item: item_to_json(item, today)})

        {:error, :recurrence_requires_anchor} ->
          unprocessable(conn, "A recurrence needs a due date anchor")

        {:error, changeset} ->
          conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(changeset)})
      end
    else
      err -> handle_error(conn, err)
    end
  end

  # PATCH /api/v1/organizations/:org_id/personal/items/:id
  def update(conn, %{"org_id" => org_id, "id" => id, "item" => attrs}) do
    with_owned(conn, org_id, id, fn item ->
      clean =
        attrs
        |> Map.take(~w(title description status priority rank tags))
        |> put_resolved_due(attrs)

      case Personal.update_item(item, clean, get_user_id(conn)) do
        {:ok, updated} ->
          json(conn, %{item: item_to_json(updated, today_for(attrs))})

        {:error, changeset} ->
          conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(changeset)})
      end
    end)
  end

  # POST /api/v1/organizations/:org_id/personal/items/:id/complete
  def complete(conn, %{"org_id" => org_id, "id" => id} = params) do
    with_owned(conn, org_id, id, fn item ->
      case Personal.complete_item(item, get_user_id(conn)) do
        {:ok, %{completed: completed, next: next}} ->
          today = Recurrence.today_in_zone(params["tz"])

          json(conn, %{
            completed: item_to_json(completed, today),
            next: next && item_to_json(next, today)
          })

        {:error, reason} ->
          unprocessable(conn, "Could not complete: #{inspect(reason)}")
      end
    end)
  end

  # POST /api/v1/organizations/:org_id/personal/items/:id/recurrence
  def set_recurrence(conn, %{"org_id" => org_id, "id" => id, "recurrence" => recurrence}) do
    with_owned(conn, org_id, id, fn item ->
      case Personal.set_recurrence(item, recurrence, get_user_id(conn)) do
        {:ok, updated} ->
          json(conn, %{item: item_to_json(updated, today_for(%{}))})

        {:error, :recurrence_requires_anchor} ->
          unprocessable(conn, "A recurrence needs a due date anchor")

        {:error, reason} ->
          unprocessable(conn, "Invalid recurrence: #{inspect(reason)}")
      end
    end)
  end

  # DELETE /api/v1/organizations/:org_id/personal/items/:id/recurrence
  def clear_recurrence(conn, %{"org_id" => org_id, "id" => id}) do
    with_owned(conn, org_id, id, fn item ->
      {:ok, updated} = Personal.clear_recurrence(item)
      json(conn, %{item: item_to_json(updated, today_for(%{}))})
    end)
  end

  # ── helpers ───────────────────────────────────────────────────────

  # Authorize member + load the item + enforce the ownership guard.
  defp with_owned(conn, org_id, id, fun) do
    user_id = get_user_id(conn)

    with {:ok, _} <- Authz.authorize(user_id, "organization", org_id, "member"),
         {:ok, item} <- Personal.fetch_owned(org_id, resolve_id(id), user_id) do
      fun.(item)
    else
      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "Item not found"})

      {:error, :forbidden} ->
        conn |> put_status(:forbidden) |> json(%{error: "Not your personal item"})

      err ->
        handle_error(conn, err)
    end
  end

  # :id may be a UUID or a human key. Personal items are org-numbered, so a key
  # resolves via the shared fetch; here we only pass through the UUID form and let
  # fetch_owned handle lookup. (Keys are resolved by the domain get if UUID cast
  # fails — kept simple: personal items are addressed by UUID in the app.)
  defp resolve_id(id), do: id

  defp item_to_json(t, today) do
    %{
      id: t.id,
      key: t.key,
      number: t.number,
      organization_id: t.organization_id,
      owner_user_id: t.owner_user_id,
      project_id: t.project_id,
      title: t.title,
      description: t.description,
      item_type: t.item_type,
      status: t.status,
      priority: t.priority,
      rank: t.rank,
      due_date: t.due_date,
      start_date: t.start_date,
      tags: t.tags || [],
      recurrence: Personal.recurrence_for(t.id),
      overdue: Personal.overdue?(t, today),
      bucket: Personal.bucket_for(t, today),
      inserted_at: t.inserted_at,
      updated_at: t.updated_at
    }
  end

  # Resolve a due-date input: an ISO date passes through; a relative phrase
  # ("today", "next monday", "in 3 days") is resolved server-side in the user tz.
  defp resolve_due(nil, _tz), do: nil
  defp resolve_due("", _tz), do: nil

  defp resolve_due(input, tz) when is_binary(input) do
    case Recurrence.parse_shorthand(input, tz) do
      {:ok, date} -> date
      _ -> input
    end
  end

  defp resolve_due(input, _tz), do: input

  defp put_resolved_due(clean, attrs) do
    case Map.fetch(attrs, "due_date") do
      {:ok, raw} -> Map.put(clean, "due_date", resolve_due(raw, attrs["tz"]))
      :error -> clean
    end
  end

  defp today_for(attrs), do: Recurrence.today_in_zone(attrs["tz"])

  defp split_tags(nil), do: nil
  defp split_tags(""), do: nil
  defp split_tags(tag) when is_binary(tag), do: String.split(tag, ",", trim: true)

  defp put_opt(opts, _key, nil), do: opts
  defp put_opt(opts, _key, ""), do: opts
  defp put_opt(opts, _key, []), do: opts
  defp put_opt(opts, key, val), do: Keyword.put(opts, key, val)

  defp unprocessable(conn, msg),
    do: conn |> put_status(:unprocessable_entity) |> json(%{error: msg})

  defp handle_error(conn, err) do
    case err do
      {:error, :not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "Organization not found"})

      {:error, :not_a_member} ->
        conn |> put_status(:forbidden) |> json(%{error: "Not a member of this organization"})

      _ ->
        conn |> put_status(:forbidden) |> json(%{error: "Insufficient permissions"})
    end
  end

  defp get_user_id(conn) do
    case Therobotplans.Guardian.Plug.current_resource(conn) do
      %Therobotplans.Users.Sessions.UserSession{user: {:ref, _, id}} -> id
      %Therobotplans.Users.Sessions.UserSession{user: %{id: id}} -> id
      _ -> nil
    end
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
