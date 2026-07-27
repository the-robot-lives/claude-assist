defmodule TimelyWeb.WellKnownController do
  @moduledoc """
  App-association documents for verified deep links:
  `/.well-known/assetlinks.json` (Android App Links) and
  `/.well-known/apple-app-site-association` (iOS Universal Links).

  ## Why these are served from config rather than as static files

  The payload is a signing-certificate fingerprint, which is an **ops** value:
  it comes from the release keystore, differs between debug and release builds,
  and rotates independently of the application. Baking it into `priv/static`
  would mean a fingerprint change needs an image rebuild and redeploy. Reading
  it from the environment means it is set the same way every other secret is.

  ## Requirements that are easy to get wrong

  Both documents MUST be served:

  - at the exact apex path, over https;
  - with `Content-Type: application/json` - and for the Apple one, with **no
    file extension**;
  - with **no redirect**. Neither platform's verifier follows one, so a
    well-meaning `http -> https` or trailing-slash redirect breaks verification
    with no useful diagnostic;
  - without authentication.

  They are therefore outside every pipeline in the router.

  ## Unconfigured means 404

  An unconfigured deployment answers `404` rather than an empty document.
  Android's verifier treats a well-formed file with no matching fingerprint as a
  definitive *rejection*, which is a confusing failure to debug; a 404 leaves
  verification unattempted, and an unverified App Link falls back to the
  disambiguation dialog rather than breaking. Failing open is the correct
  behaviour while an app is being staged.
  """
  use TimelyWeb, :controller

  @doc """
  Android App Links. Grants `delegate_permission/common.handle_all_urls` to the
  configured package for every fingerprint listed.
  """
  # ⟦𓄿𓋴𓋴𓏏⟧ assetlinks :: Serves /.well-known/assetlinks.json.
  def assetlinks(conn, _params) do
    package = Application.get_env(:timely, :android_app_package)
    fingerprints = Application.get_env(:timely, :android_app_fingerprints, [])

    if is_binary(package) and package != "" and fingerprints != [] do
      send_association(conn, [
        %{
          "relation" => ["delegate_permission/common.handle_all_urls"],
          "target" => %{
            "namespace" => "android_app",
            "package_name" => package,
            "sha256_cert_fingerprints" => fingerprints
          }
        }
      ])
    else
      not_configured(conn)
    end
  end

  @doc """
  iOS Universal Links. Served with no file extension, as Apple requires.
  """
  # ⟦𓄿𓄿𓋴𓄿⟧ apple_app_site_association :: Serves the iOS association file.
  def apple_app_site_association(conn, _params) do
    app_ids = Application.get_env(:timely, :ios_app_ids, [])

    if app_ids != [] do
      send_association(conn, %{
        "applinks" => %{
          "apps" => [],
          "details" =>
            Enum.map(app_ids, fn app_id ->
              %{"appID" => app_id, "paths" => ["/app/auth/callback", "/app/auth/*"]}
            end)
        }
      })
    else
      not_configured(conn)
    end
  end

  # Content-Type is set explicitly rather than via `json/2`, because the Apple
  # document is served from an extensionless path and content negotiation would
  # otherwise have nothing to work from.
  defp send_association(conn, payload) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(payload))
  end

  defp not_configured(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(404, Jason.encode!(%{"error" => "not_configured"}))
  end
end
