defmodule Therobotknows.Collab do
  @moduledoc "Universe collaboration invites (M5.S5.4)."

  import Ecto.Query
  alias Therobotknows.Repo
  alias Therobotknows.Universes
  alias Therobotknows.Schema.Collab.Invite
  alias Therobotknows.Schema.Universe.Member
  alias Therobotknows.Schema.Universe.Universe

  def list_invites(universe_id_or_slug, user_id) do
    with {:ok, universe, role} <- Universes.authorize(universe_id_or_slug, user_id, :editor),
         true <- role in ["owner", "editor"] do
      invites =
        from(i in Invite,
          where: i.universe_id == ^universe.id and is_nil(i.revoked_at),
          order_by: [desc: i.inserted_at]
        )
        |> Repo.all()
        |> Enum.map(&invite_map/1)

      {:ok, %{invites: invites}}
    else
      false -> {:error, :forbidden}
      e -> e
    end
  end

  def invite(universe_id_or_slug, email, role, user_id) do
    with {:ok, universe, member_role} <- Universes.authorize(universe_id_or_slug, user_id, :owner),
         true <- member_role == "owner" do
      token = :crypto.strong_rand_bytes(24) |> Base.url_encode64(padding: false)

      %Invite{}
      |> Invite.changeset(%{
        universe_id: universe.id,
        email: String.downcase(email),
        role: role || "editor",
        token: token,
        invited_by: user_id,
        inserted_at: DateTime.utc_now() |> DateTime.truncate(:microsecond)
      })
      |> Repo.insert()
      |> case do
        {:ok, inv} -> {:ok, invite_map(inv)}
        e -> e
      end
    else
      false -> {:error, :forbidden}
      e -> e
    end
  end

  def accept(token, user_id, user_email) do
    case Repo.get_by(Invite, token: token) do
      nil ->
        {:error, :not_found}

      %Invite{revoked_at: r} when not is_nil(r) ->
        {:error, :revoked}

      %Invite{accepted_at: a} when not is_nil(a) ->
        {:error, :already_accepted}

      %Invite{} = inv ->
        if String.downcase(user_email || "") != String.downcase(inv.email) do
          {:error, :email_mismatch}
        else
          Repo.transaction(fn ->
            case Repo.get_by(Member, universe_id: inv.universe_id, user_id: user_id) do
              nil ->
                %Member{}
                |> Member.changeset(%{
                  universe_id: inv.universe_id,
                  user_id: user_id,
                  role: inv.role
                })
                |> Repo.insert!()

              _ ->
                :ok
            end

            inv
            |> Invite.changeset(%{
              accepted_at: DateTime.utc_now() |> DateTime.truncate(:microsecond)
            })
            |> Repo.update!()
          end)
          |> case do
            {:ok, _} -> {:ok, %{universe_id: inv.universe_id, role: inv.role}}
            e -> e
          end
        end
    end
  end

  def set_public(universe_id_or_slug, public_read, user_id) do
    with {:ok, universe, role} <- Universes.authorize(universe_id_or_slug, user_id, :owner),
         true <- role == "owner" do
      # public_read column from 085 — update via SQL if schema field not loaded
      case Ecto.Adapters.SQL.query(
             Repo,
             "UPDATE universes SET public_read = $1, updated_at = now() WHERE id = $2::uuid RETURNING id, public_read",
             [!!public_read, universe.id]
           ) do
        {:ok, %{rows: [[id, pub]]}} ->
          {:ok, %{id: id, public_read: pub}}

        {:ok, %{num_rows: 0}} ->
          {:error, :not_found}

        {:error, err} ->
          {:error, err}
      end
    else
      false -> {:error, :forbidden}
      e -> e
    end
  end

  defp invite_map(%Invite{} = i) do
    %{
      id: i.id,
      universe_id: i.universe_id,
      email: i.email,
      role: i.role,
      token: i.token,
      invited_by: i.invited_by,
      accepted_at: i.accepted_at,
      inserted_at: i.inserted_at
    }
  end
end
