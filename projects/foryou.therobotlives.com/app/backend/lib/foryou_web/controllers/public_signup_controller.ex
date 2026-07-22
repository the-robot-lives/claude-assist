defmodule ForyouWeb.PublicSignupController do
  @moduledoc """
  Public, unauthenticated signup surface. CORS-open (endpoint-global plug),
  rate-limited (`:rate_limited_signup`, 5/60s per IP — D17), honeypot-filtered,
  and no-leak: every well-formed signup returns an identical generic 202
  regardless of outcome (D2/US-045). Token confirm/unsubscribe render simple HTML
  pages that need no login.
  """
  use ForyouWeb, :controller

  alias Foryou.{Lists, Signups}

  @generic_body %{accepted: true}
  # Collision-safe honeypot names only — a bare "website" could shadow a real
  # declared attribute and silently drop legitimate signups.
  @honeypot_fields ~w(company_website hp_field _gotcha)

  # ── Manifest (widget reads the attribute schema at runtime) ─────

  def manifest(conn, %{"public_slug" => public_slug}) do
    render_manifest(conn, Lists.get_by_public_slug(public_slug))
  end

  def manifest(conn, %{"service_slug" => svc, "list_slug" => list_slug}) do
    render_manifest(conn, Lists.get_by_service_slugs(svc, list_slug))
  end

  defp render_manifest(conn, nil),
    do: conn |> put_status(:not_found) |> json(%{error: "not found"})

  defp render_manifest(conn, %{status: "archived"} = _list),
    do: conn |> put_status(:not_found) |> json(%{error: "not found"})

  defp render_manifest(conn, list) do
    attributes =
      list.id
      |> Lists.list_attributes()
      |> Enum.map(fn a ->
        %{
          slug: a.slug,
          name: a.name,
          type: a.type,
          required: a.required,
          is_identity: a.is_identity,
          options: a.options,
          validation: a.validation,
          sort_order: a.sort_order
        }
      end)

    json(conn, %{
      list: %{
        id: list.id,
        public_slug: list.public_slug,
        name: list.name,
        description: list.description,
        kind: list.kind,
        opt_in_mode: to_string(Signups.opt_in_mode(list)),
        settings: manifest_settings(list.settings),
        attributes: attributes
      }
    })
  end

  # only expose branding/public-safe settings, never internal config
  defp manifest_settings(settings) when is_map(settings) do
    Map.take(settings, ["branding", "preference_defaults", "available_channels", "success_message"])
  end

  defp manifest_settings(_), do: %{}

  # ── Signup create ──────────────────────────────────────────────

  def create(conn, %{"public_slug" => public_slug} = params) do
    handle_signup(conn, Lists.get_by_public_slug(public_slug), params)
  end

  def create_alias(conn, %{"service_slug" => svc, "list_slug" => list_slug} = params) do
    handle_signup(conn, Lists.get_by_service_slugs(svc, list_slug), params)
  end

  # No-leak: whether the list exists, is archived, honeypot-tripped, validation
  # failed, or the email is already a member — the response is byte-identical.
  defp handle_signup(conn, list, params) do
    values = params["values"] || Map.drop(params, non_value_keys())

    unless honeypot_tripped?(params) or is_nil(list) do
      meta = %{source: params["source"], submitter_ip: remote_ip(conn), suppress_email: false}
      _ = Signups.add_signup(list, values, meta, Noizu.Context.system())
    end

    accepted(conn)
  end

  # ── Resend ─────────────────────────────────────────────────────

  def resend(conn, %{"email" => email} = params) do
    list =
      cond do
        params["public_slug"] -> Lists.get_by_public_slug(params["public_slug"])
        params["service_slug"] && params["list_slug"] ->
          Lists.get_by_service_slugs(params["service_slug"], params["list_slug"])
        true -> nil
      end

    if list && is_binary(email), do: Signups.resend_confirmation(list, email)
    accepted(conn)
  end

  def resend(conn, _params), do: accepted(conn)

  # ── Confirm / Unsubscribe (HTML pages) ─────────────────────────

  def confirm(conn, %{"token" => token}) do
    case Signups.confirm_signup(token) do
      {:ok, _signup} ->
        html_page(conn, 200, "Subscription confirmed",
          "Your subscription is confirmed. Thank you!")

      {:error, _} ->
        html_page(conn, 200, "Link expired",
          "This confirmation link is invalid or has expired. You can request a new one from the signup form.")
    end
  end

  def confirm(conn, _), do: html_page(conn, 400, "Invalid request", "Missing confirmation token.")

  def unsubscribe(conn, %{"token" => token}) do
    case Signups.unsubscribe_by_token(token) do
      {:ok, _signup} ->
        html_page(conn, 200, "Unsubscribed",
          "You've been unsubscribed. You won't receive further emails from this list.")

      {:error, _} ->
        html_page(conn, 200, "No change",
          "This link is invalid or already used. No change was made.")
    end
  end

  def unsubscribe(conn, _), do: html_page(conn, 400, "Invalid request", "Missing token.")

  # ── Helpers ────────────────────────────────────────────────────

  defp accepted(conn), do: conn |> put_status(:accepted) |> json(@generic_body)

  defp honeypot_tripped?(params) do
    Enum.any?(@honeypot_fields, fn f ->
      case params[f] do
        nil -> false
        "" -> false
        _ -> true
      end
    end)
  end

  defp non_value_keys do
    ~w(public_slug service_slug list_slug source values) ++ @honeypot_fields
  end

  defp remote_ip(conn) do
    case get_req_header(conn, "x-forwarded-for") do
      [fwd | _] -> fwd |> String.split(",") |> List.first() |> String.trim()
      [] ->
        case conn.remote_ip do
          {a, b, c, d} -> "#{a}.#{b}.#{c}.#{d}"
          _ -> nil
        end
    end
  end

  defp html_page(conn, status, title, body) do
    html = """
    <!doctype html><html><head><meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>#{title}</title></head>
    <body style="font-family:system-ui,sans-serif;max-width:32rem;margin:4rem auto;padding:0 1rem;color:#111;">
    <h1 style="font-size:1.5rem;">#{title}</h1>
    <p style="color:#444;line-height:1.6;">#{body}</p>
    </body></html>
    """

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(status, html)
  end
end
