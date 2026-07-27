defmodule Timely.Sync.WireFixturesTest do
  @moduledoc """
  Generates `apps/shared/contracts/wire-fixtures.json` **and** guards it against
  drift, from one code path.

  Generation and verification being the same code is the whole design. If the
  generator lived somewhere else, the committed file could agree with the
  generator while both disagreed with the server. Here the file is compared to a
  fresh capture of the real router on every test run, so it cannot silently go
  stale.

  Regenerate with `apps/shared/contracts/gen-wire-fixtures.sh`, which sets
  `WIRE_FIXTURES=overwrite` and runs this module.

  The rationale for the file's existence: `canon-fixtures.json` worked because it
  was executable and generated, not because it was documented. Prose failed
  repeatedly on this project - SYNC-PROTOCOL §3.3 was stale for hours and two
  separate briefs got the quote set wrong. These fixtures pin the wire-level
  semantics a JSON schema cannot express, so a client that gets one wrong fails
  a test instead of shipping the bug.
  """
  use TimelyWeb.ConnCase, async: false

  import Ecto.Query
  import Timely.TimelyFixtures
  import Timely.WireRecorder, only: [label: 2, record: 3]

  alias Timely.Sync.Blobs
  alias Timely.Sync.Canon
  alias Timely.WireRecorder

  @fixture_path Path.expand("../../../../shared/contracts/wire-fixtures.json", __DIR__)

  setup %{conn: conn} do
    Blobs.Memory.reset()
    WireRecorder.start()

    %{user: user, access_token: token} = setup_user_and_token()

    {:ok, conn: authenticated_conn(conn, token), user: user}
  end

  test "wire fixtures are a faithful transcript of the live server", %{conn: conn, user: user} do
    build_all(conn, user)

    document = document(WireRecorder.cases(), WireRecorder.placeholders())
    encoded = WireRecorder.encode(document)

    if System.get_env("WIRE_FIXTURES") == "overwrite" do
      File.write!(@fixture_path, encoded)
    end

    committed = File.read!(@fixture_path)

    assert committed == encoded, """
    wire-fixtures.json no longer matches what the server emits.

    Something in the wire format changed. Either that change is intended, in
    which case regenerate with

        apps/shared/contracts/gen-wire-fixtures.sh

    and review the diff before committing it - the Swift and Kotlin suites
    assert against this file, so a change here is a change to their contract -
    or it is a regression and the server is what needs fixing.
    """
  end

  # ---------------------------------------------------------------------------
  # Scenarios
  # ---------------------------------------------------------------------------

  defp build_all(conn, user) do
    devices(conn, user)
    changes(conn, user)
    mutations_basics(conn, user)
    end_null_versus_absent(conn, user)
    conflicts_and_replays(conn, user)
    settings(conn, user)
    screenshots(conn, user)
    reports(conn, user)
    adjudication(conn, user)
    sso(conn)
  end

  # -- tie-break and staleness ------------------------------------------------

  # Sorts below @high_device, and both sort ABOVE the empty string - which is
  # what a client that omits the field used to be compared as.
  @low_device "019318a0-0000-7000-8000-000000000000"
  @high_device "019318a0-ffff-7000-8000-ffffffffffff"
  # In the PAST, so the clamp leaves it untouched and the tie is exact. A future
  # instant is replaced by the server clock at receipt, and two pushes then
  # differ by milliseconds - which would quietly make these plain timestamp
  # comparisons rather than tie-breaks.
  @tie_at "2026-07-25T10:00:00.000000Z"

  defp adjudication(conn, user) do
    workspace_id = label(workspace!(), "workspace_id")
    member!(user.id, workspace_id, "owner")

    span_id = label(uuid7(), "span_id")

    tie_payload = fn title ->
      %{
        "id" => span_id,
        "title" => title,
        "start" => "2026-07-25T09:00:00.000000Z",
        "end" => @tie_at,
        "source" => "timer",
        "updated_at" => @tie_at
      }
    end

    record(
      conn,
      %{
        "id" => "wire-090",
        "group" => "tie-break",
        "name" => "a row authored by the LOW-sorting device",
        "note" =>
          "Setup for wire-091. Note the response's origin_device_id: the request omitted the " <>
            "field, and the server substituted the PUSHING device."
      },
      method: "POST",
      path: "/api/v1/sync/mutations",
      body: %{
        "workspace_id" => workspace_id,
        "device_id" => label(@low_device, "low_device"),
        "mutations" => [
          %{
            "mutation_id" => label(uuid7(), "mutation_id"),
            "entity" => "time_span",
            "op" => "create",
            "payload" => tie_payload.("from the low device")
          }
        ]
      }
    )

    record(
      conn,
      %{
        "id" => "wire-091",
        "group" => "tie-break",
        "name" => "OMITTING origin_device_id still wins the tie on merit",
        "trap" => true,
        "note" =>
          "Identical updated_at, so §8.1's tie-break decides: the lexically greater " <>
            "origin_device_id wins. The request OMITS the field and still wins, because the " <>
            "server adjudicates on the DERIVED value - the same one it stores - not on the raw " <>
            "payload. Adjudicating on the payload would compare \"\" against a real id and lose " <>
            "every tie, and, worse, two clients with different serialization habits would " <>
            "compute DIFFERENT winners from the same two versions. §8.1 chose this tie-break " <>
            "precisely because every client can compute it identically without asking the " <>
            "server, and what a client sees is the STORED value it pulled - never another " <>
            "device's request body. So `origin_device_id` is safely omittable."
      },
      method: "POST",
      path: "/api/v1/sync/mutations",
      body: %{
        "workspace_id" => workspace_id,
        "device_id" => label(@high_device, "high_device"),
        "mutations" => [
          %{
            "mutation_id" => label(uuid7(), "mutation_id"),
            "entity" => "time_span",
            "op" => "update",
            "payload" => tie_payload.("from the high device")
          }
        ]
      }
    )

    record(
      conn,
      %{
        "id" => "wire-092",
        "group" => "tie-break",
        "name" => "the substitution is not a thumb on the scale",
        "note" =>
          "The mirror of wire-091: the low device pushes at the same instant, omits the field, " <>
            "and correctly LOSES. `status` is still `applied` - the mutation was processed and " <>
            "evaluated - with `stale_base: true` and the authoritative row returned. \"Applied\" " <>
            "never meant \"your version won\"."
      },
      method: "POST",
      path: "/api/v1/sync/mutations",
      body: %{
        "workspace_id" => workspace_id,
        "device_id" => @low_device,
        "mutations" => [
          %{
            "mutation_id" => label(uuid7(), "mutation_id"),
            "entity" => "time_span",
            "op" => "update",
            "payload" => tie_payload.("from the low device, again")
          }
        ]
      }
    )

    bogus_id = label(uuid7(), "bogus_span_id")

    record(
      conn,
      %{
        "id" => "wire-095",
        "group" => "tie-break",
        "name" => "a client-asserted origin_device_id is HONOURED, not overridden",
        "trap" => true,
        "note" =>
          "The limit of the guarantee, pinned so nobody assumes more than is offered. This " <>
            "request is pushed by the LOW device but stamps `origin_device_id` with a " <>
            "high-sorting value, and it WINS the tie - the payload value is honoured when " <>
            "present. §8.1 promises CONVERGENCE (every client computes the same winner from " <>
            "the same two stored versions), not UNFORGEABILITY. Device identity is " <>
            "client-asserted throughout: the bearer token identifies a user and a session, " <>
            "never a device, and MutationRequest.device_id is supplied by the client too - so " <>
            "ignoring the payload would move the assertion rather than remove it. The value " <>
            "must be a well-formed uuid (an arbitrary high-sorting STRING is rejected " <>
            "validation_failed), but since real ids are UUIDv7 and therefore timestamp-led, " <>
            "an all-f uuid outranks every genuine one. Not a tenancy hole: workspace " <>
            "isolation is enforced separately, so the only rows a client can influence this " <>
            "way are its own, in its own workspace, against its own other devices."
      },
      method: "POST",
      path: "/api/v1/sync/mutations",
      body: %{
        "workspace_id" => workspace_id,
        "device_id" => @low_device,
        "mutations" => [
          %{
            "mutation_id" => label(uuid7(), "mutation_id"),
            "entity" => "time_span",
            "op" => "create",
            "payload" =>
              Map.merge(tie_payload.("stamped with a borrowed id"), %{
                "id" => bogus_id,
                "origin_device_id" => "ffffffff-ffff-7fff-bfff-ffffffffffff"
              })
          }
        ]
      }
    )

    locked =
      span!(workspace_id,
        title: "An approved day",
        start_at: ~U[2026-07-25 09:00:00.000000Z],
        locked_at: ~U[2026-07-26 12:00:00.000000Z]
      )

    locked_id = label(locked.id, "locked_span_id")

    unlock_payload = %{
      "id" => locked_id,
      "title" => "Reopening an approved day",
      "start" => "2026-07-25T09:00:00.000000Z",
      "locked_at" => nil,
      # Just ahead of the server clock: late enough to win LWW against the row
      # the fixture just wrote, but inside the 300s skew tolerance so this case
      # stays about unlocking and does not also raise `low_confidence`.
      "updated_at" => iso(60)
    }

    record(
      conn,
      %{
        "id" => "wire-093",
        "group" => "tie-break",
        "name" => "an admin unlocking from a STALE base is rejected",
        "trap" => true,
        "note" =>
          "Conflict matrix row 11's escape hatch requires a CURRENT base_revision, exactly as " <>
            "the reopen guard does. A deliberate unlock and an accidental one look identical " <>
            "in the payload; the only thing separating them is whether the actor could see " <>
            "what they were undoing. Without this an admin whose copy predated the approval " <>
            "could clear a lock they had never seen - which is why `locked_at` was on every " <>
            "client's never-send list, and why US-068 was inexpressible from any native " <>
            "surface."
      },
      method: "POST",
      path: "/api/v1/sync/mutations",
      body: %{
        "workspace_id" => workspace_id,
        "device_id" => @high_device,
        "mutations" => [
          %{
            "mutation_id" => label(uuid7(), "mutation_id"),
            "entity" => "time_span",
            "op" => "update",
            "base_revision" => locked.server_revision - 1,
            "payload" => unlock_payload
          }
        ]
      }
    )

    record(
      conn,
      %{
        "id" => "wire-094",
        "group" => "tie-break",
        "name" => "an admin unlocking from a CURRENT base succeeds and is audited",
        "note" =>
          "The same payload as wire-093 with a current base_revision. Applied, `locked_at` is " <>
            "cleared, and a `reopened_after_approval` review reason is raised on the row - " <>
            "reopening an approved day is an auditable event, never a silent edit. A client " <>
            "may safely send `locked_at` again."
      },
      method: "POST",
      path: "/api/v1/sync/mutations",
      body: %{
        "workspace_id" => workspace_id,
        "device_id" => @high_device,
        "mutations" => [
          %{
            "mutation_id" => label(uuid7(), "mutation_id"),
            "entity" => "time_span",
            "op" => "update",
            "base_revision" => locked.server_revision,
            "payload" => unlock_payload
          }
        ]
      }
    )
  end

  # -- native SSO -------------------------------------------------------------

  @native_redirect "com.noizu.timely://auth/callback"
  @pkce_verifier "dBjftJeZ4CVPmB92K27uhbUJU1p1r_wW1gFWFOEjXk"
  @pkce_challenge :sha256 |> :crypto.hash(@pkce_verifier) |> Base.url_encode64(padding: false)

  defp sso(conn) do
    previous = Application.get_env(:timely, :sso_redirect_allowlist)
    Application.put_env(:timely, :sso_redirect_allowlist, [@native_redirect])
    on_exit(fn -> restore_allowlist(previous) end)

    # An anonymous conn: the SSO exchange is what a client calls when it has no
    # token yet, so recording it from an authenticated conn would prove nothing.
    anon = Phoenix.ConnTest.build_conn()

    record(
      Plug.Test.init_test_session(anon, %{sso_redirect: @native_redirect}),
      %{
        "id" => "wire-080",
        "group" => "sso-native",
        "name" => "the callback hands back to the app's OWN url scheme",
        "trap" => true,
        "note" =>
          "The whole reason native SSO needed server work. ASWebAuthenticationSession only " <>
            "returns control to the app when the browser reaches the app's own scheme; a " <>
            "relative https path never does, so the previous behaviour left the session open " <>
            "and the app hung with nothing to show. Note the Location scheme - that, not the " <>
            "body, is the contract here. Errors take the SAME route for the same reason: an " <>
            "error rendered on a web page would hang the session just as thoroughly."
      },
      method: "GET",
      path: "/auth/oidc/callback"
    )

    Application.put_env(:timely, :sso_redirect_allowlist, [
      @native_redirect,
      "https://timely.noizu.com/app/auth/callback"
    ])

    record(
      Plug.Test.init_test_session(anon, %{
        sso_redirect: "https://timely.noizu.com/app/auth/callback"
      }),
      %{
        "id" => "wire-086",
        "group" => "sso-native",
        "name" => "an https App Link is a first-class redirect target",
        "trap" => true,
        "note" =>
          "The production Android target. Preferred over a custom scheme because a custom " <>
            "scheme is claimed by PATTERN while an App Link is ownership-VERIFIED through " <>
            "/.well-known/assetlinks.json - which demotes PKCE from the only control to " <>
            "defence in depth. Requires that assetlinks.json be served at the apex path, as " <>
            "application/json, with NO redirect, since the verifier will not follow one. " <>
            "Note also that AppAuth's `com.noizu.timely:/oauth2redirect` (ONE slash) and " <>
            "`com.noizu.timely://oauth2redirect` (TWO) are DIFFERENT URIs by RFC 3986 and are " <>
            "kept distinct by the exact-match allow-list: allow-listing one does not admit the " <>
            "other, and the mismatch appears only at runtime as redirect_not_allowed."
      },
      method: "GET",
      path: "/auth/oidc/callback"
    )

    Application.put_env(:timely, :sso_redirect_allowlist, [@native_redirect])

    record(
      Plug.Test.init_test_session(anon, %{}),
      %{
        "id" => "wire-081",
        "group" => "sso-native",
        "name" => "a web flow still gets the relative path, unchanged",
        "note" =>
          "No redirect_uri was requested, so the flow lands where it always did. This is what " <>
            "keeps the Hologram dashboard working and is the default for any client that does " <>
            "not opt in."
      },
      method: "GET",
      path: "/auth/oidc/callback"
    )

    record(
      anon,
      %{
        "id" => "wire-082",
        "group" => "sso-native",
        "name" => "an unlisted redirect_uri is refused BEFORE the user leaves",
        "trap" => true,
        "note" =>
          "The redirect carries a one-time code that trades for an access AND refresh token, " <>
            "so reflecting a client-supplied redirect_uri would be token exfiltration rather " <>
            "than a mere open redirect. Targets come from a server-side allow-list, matched by " <>
            "EXACT string - prefix matching is defeated by " <>
            "`com.noizu.timely://auth/callback@evil.example`. Refused at init, not at " <>
            "callback: a flow whose landing place is not permitted must not start."
      },
      method: "GET",
      path: "/auth/oidc",
      query: %{"redirect_uri" => "https://evil.example/steal"}
    )

    # A deterministic principal: `setup_user_and_token` mints unique emails and
    # handles per run, which would make this file differ on every regeneration.
    user = fixed_user()
    session = fixed_session(user)

    {:ok, unbound_code} = Timely.Auth.SSOCode.create(session.id)

    record(
      anon,
      %{
        "id" => "wire-083",
        "group" => "sso-native",
        "name" => "exchange a one-time code for tokens",
        "note" =>
          "The field names both mobile clients asked about: access_token and refresh_token. " <>
            "There is no bare `token` in any response - the `token` parameter that appears " <>
            "elsewhere in the auth API is an inbound magic-link/verify-email value. The code " <>
            "is single-use: a second exchange answers 401."
      },
      method: "POST",
      path: "/api/v1/auth/sso/exchange",
      body: %{"code" => label(unbound_code, "sso_code")}
    )

    {:ok, bound_code} = Timely.Auth.SSOCode.create(session.id, code_challenge: @pkce_challenge)

    record(
      anon,
      %{
        "id" => "wire-084",
        "group" => "sso-native",
        "name" => "a PKCE-bound code is refused without the verifier",
        "trap" => true,
        "note" =>
          "On iOS and Android a custom URL scheme is claimed by pattern, not owned, so a " <>
            "malicious app registering com.noizu.timely:// can receive the redirect. Being " <>
            "single-use and short-lived does not help: whoever wins the race redeems it. PKCE " <>
            "closes that - the intercepting app holds the code but not the verifier. Note that " <>
            "this is PKCE on OUR code between app and server, NOT against the identity " <>
            "provider, where it does not apply because the server is a confidential client and " <>
            "the app never speaks to the IdP. A failed attempt still CONSUMES the code, so " <>
            "verifiers cannot be probed against a live one."
      },
      method: "POST",
      path: "/api/v1/auth/sso/exchange",
      body: %{"code" => label(bound_code, "sso_code")}
    )

    {:ok, bound_again} = Timely.Auth.SSOCode.create(session.id, code_challenge: @pkce_challenge)

    record(
      anon,
      %{
        "id" => "wire-085",
        "group" => "sso-native",
        "name" => "a PKCE-bound code exchanges with the matching verifier",
        "note" =>
          "code_challenge = BASE64URL(SHA256(code_verifier)), sent at /auth/oidc; the verifier " <>
            "itself is presented only here. S256 only - `plain` is refused, since it offers " <>
            "nothing against an interceptor who saw the challenge."
      },
      method: "POST",
      path: "/api/v1/auth/sso/exchange",
      body: %{
        "code" => label(bound_again, "sso_code"),
        "code_verifier" => @pkce_verifier
      }
    )

    restore_allowlist(previous)
  end

  defp restore_allowlist(nil), do: Application.delete_env(:timely, :sso_redirect_allowlist)
  defp restore_allowlist(value), do: Application.put_env(:timely, :sso_redirect_allowlist, value)

  defp fixed_user do
    {:ok, user} =
      Timely.Repo.insert(%Timely.Schema.Users.User{
        id: label("019318d0-0000-7000-8000-000000000001", "user_id"),
        email: "sso-fixture@example.com",
        user_name: "ssofixture",
        handle: "ssofixture",
        status: :active,
        verified: true,
        flagged: false
      })

    user
  end

  defp fixed_session(user) do
    {:ok, session} =
      Timely.Repo.insert(%Timely.Schema.Users.Sessions.UserSession{
        id: label("019318d0-0000-7000-8000-000000000002", "session_id"),
        user_id: user.id,
        status: :active,
        details: %{}
      })

    session
  end

  # -- devices ----------------------------------------------------------------

  defp devices(conn, user) do
    workspace_id = label(workspace!(), "workspace_id")
    member!(user.id, workspace_id, "owner")
    device_id = label(uuid7(), "device_id")
    label(user.id, "user_id")

    record(
      conn,
      %{
        "id" => "wire-001",
        "group" => "devices",
        "name" => "register a macOS capture agent",
        "note" =>
          "Idempotent by client-supplied device_id. local_only_screenshots defaults to true; " <>
            "a device can only ever tighten the upload gate, never loosen it."
      },
      method: "POST",
      path: "/api/v1/devices",
      body: %{
        "device_id" => device_id,
        "workspace_id" => workspace_id,
        "platform" => "macos",
        "name" => "Keith's MacBook Pro",
        "app_version" => "1.0.0",
        "os_version" => "26.1",
        "local_only_screenshots" => true,
        "is_capture_agent" => true
      }
    )

    record(
      conn,
      %{
        "id" => "wire-002",
        "group" => "devices",
        "name" => "re-registering the same device_id updates in place",
        "note" =>
          "created_at is unchanged from wire-001: the row is reused so origin_device_id " <>
            "history, and every LWW tie-break that depends on it, survives a reinstall."
      },
      method: "POST",
      path: "/api/v1/devices",
      body: %{
        "device_id" => device_id,
        "workspace_id" => workspace_id,
        "platform" => "macos",
        "name" => "Keith's MacBook Pro (16-inch)",
        "app_version" => "1.0.1"
      }
    )

    record(
      conn,
      %{
        "id" => "wire-003",
        "group" => "devices",
        "name" => "open the device half of the screenshot gate",
        "note" =>
          "PATCH exists chiefly for this flag: it is half of the upload gate and has to be " <>
            "togglable from the device that holds the bytes."
      },
      method: "PATCH",
      path: "/api/v1/devices/#{device_id}",
      body: %{"local_only_screenshots" => false}
    )

    colleague = user!()
    member!(colleague.id, workspace_id, "member")
    theirs = label(device!(workspace_id, colleague.id, platform: "ios").id, "other_device_id")

    record(
      conn,
      %{
        "id" => "wire-004",
        "group" => "devices",
        "name" => "another user's device is refused",
        "trap" => true,
        "note" =>
          "Conflict matrix row 18. PATCH carries no device identity of its own, so the server " <>
            "enforces USER ownership here; row 18 proper is enforced on /sync/mutations, where " <>
            "device_id is in the body."
      },
      method: "PATCH",
      path: "/api/v1/devices/#{theirs}",
      body: %{"name" => "hijacked"}
    )
  end

  # -- sync/changes -----------------------------------------------------------

  defp changes(conn, user) do
    workspace_id = label(workspace!(), "workspace_id")
    member!(user.id, workspace_id, "owner")

    first = label(span!(workspace_id, title: "Timeline canvas keyboard pass").id, "span_a")
    second = label(span!(workspace_id, title: "Client call").id, "span_b")
    label(span!(workspace_id, title: "Inbox triage").id, "span_c")

    record(
      conn,
      %{
        "id" => "wire-010",
        "group" => "sync-changes",
        "name" => "bootstrap from since=0",
        "trap" => true,
        "note" =>
          "All NINE buckets are present even when empty, so a client iterates a fixed key " <>
            "set. The bucket name is the type discriminator here - unlike a mutation result, " <>
            "a pulled row needs no entity_kind. Note `start`/`end` on the wire: the SQL " <>
            "columns are start_at/end_at and never appear."
      },
      method: "GET",
      path: "/api/v1/sync/changes",
      query: %{"workspace_id" => workspace_id, "since" => "0"}
    )

    page =
      record(
        conn,
        %{
          "id" => "wire-011",
          "group" => "sync-changes",
          "name" => "first page, has_more true",
          "note" =>
            "limit caps rows ACROSS ALL BUCKETS COMBINED, not per bucket, so a busy bucket " <>
              "cannot starve a quiet one. Feed next_cursor back as since."
        },
        method: "GET",
        path: "/api/v1/sync/changes",
        query: %{"workspace_id" => workspace_id, "since" => "0", "limit" => "2"}
      )

    cursor = page |> json_response(200) |> Map.fetch!("next_cursor")

    record(
      conn,
      %{
        "id" => "wire-012",
        "group" => "sync-changes",
        "name" => "resume from next_cursor, has_more false",
        "note" =>
          "since is an EXCLUSIVE lower bound. The rows from wire-011 do not repeat, and " <>
            "next_cursor now equals the committed watermark."
      },
      method: "GET",
      path: "/api/v1/sync/changes",
      query: %{"workspace_id" => workspace_id, "since" => to_string(cursor), "limit" => "2"}
    )

    record(
      conn,
      %{
        "id" => "wire-013",
        "group" => "sync-changes",
        "name" => "a tombstone is delivered like any other row",
        "note" =>
          "Deletes are tombstones, never hard deletes. Clients MUST apply them even for rows " <>
            "they have never seen, where applying is a no-op."
      },
      method: "POST",
      path: "/api/v1/sync/mutations",
      body: %{
        "workspace_id" => workspace_id,
        "device_id" => label(uuid7(), "device_id"),
        "mutations" => [
          %{
            "mutation_id" => label(uuid7(), "mutation_id"),
            "entity" => "time_span",
            "op" => "delete",
            "payload" => %{"id" => second, "deleted_at" => iso(-60)}
          }
        ]
      }
    )

    record(
      conn,
      %{
        "id" => "wire-014",
        "group" => "sync-changes",
        "name" => "tombstones only, filtered to one bucket",
        "note" =>
          "The optional entities= filter narrows the page. Unfiltered buckets are still " <>
            "present and empty. deleted_at is non-null on the tombstoned row."
      },
      method: "GET",
      path: "/api/v1/sync/changes",
      query: %{
        "workspace_id" => workspace_id,
        "since" => to_string(cursor),
        "entities" => "time_spans"
      }
    )

    _ = first

    stale = workspace!()
    member!(user.id, stale, "owner")
    span!(stale)

    Timely.Repo.update_all(
      where(Timely.Schema.Sync.WorkspaceRevision, workspace_id: ^stale),
      set: [current_revision: 100, tombstone_horizon_revision: 100]
    )

    record(
      conn,
      %{
        "id" => "wire-015",
        "group" => "sync-changes",
        "name" => "a cursor below the tombstone horizon is 410",
        "note" =>
          "The client discards its mirror and re-bootstraps from since=0. Unpushed local " <>
            "mutations SURVIVE this - the push queue is separate from the mirror."
      },
      method: "GET",
      path: "/api/v1/sync/changes",
      query: %{"workspace_id" => label(stale, "workspace_id"), "since" => "5"}
    )
  end

  # -- mutations --------------------------------------------------------------

  defp mutations_basics(conn, user) do
    workspace_id = label(workspace!(), "workspace_id")
    member!(user.id, workspace_id, "owner")
    device_id = label(uuid7(), "device_id")
    span_id = label(uuid7(), "span_id")

    record(
      conn,
      %{
        "id" => "wire-020",
        "group" => "mutations",
        "name" => "create a time span",
        "trap" => true,
        "note" =>
          "The canonical applied result. entity_kind is on the RESULT ENVELOPE, beside " <>
            "entity, not inside the row - results arrive in one flat array and nothing else " <>
            "says which kind of row entity holds. Wire field names are `start` and `end`; " <>
            "the SQL columns start_at/end_at never appear on the wire."
      },
      method: "POST",
      path: "/api/v1/sync/mutations",
      body: %{
        "workspace_id" => workspace_id,
        "device_id" => device_id,
        "mutations" => [
          %{
            "mutation_id" => label(uuid7(), "mutation_id"),
            "entity" => "time_span",
            "op" => "create",
            "base_revision" => nil,
            "payload" => %{
              "id" => span_id,
              "title" => "Timeline canvas keyboard pass",
              "start" => "2026-07-27T09:02:00.000000Z",
              "end" => "2026-07-27T10:47:30.000000Z",
              "source" => "timer",
              "is_billable" => true,
              "notes" => "",
              "updated_at" => "2026-07-27T10:47:30.000000Z",
              "origin_device_id" => device_id
            }
          }
        ]
      }
    )

    record(
      conn,
      %{
        "id" => "wire-021",
        "group" => "mutations",
        "name" => "auto-vivification returns side effects",
        "note" =>
          "A span naming a client and project that do not exist yet does not fail. The " <>
            "server mints them with the deterministic UUIDv5 ids from SYNC-PROTOCOL 3.2, " <>
            "marks them auto_created + needs_review, and returns them in side_effects so the " <>
            "pusher can render a project name without waiting for the next pull. Each side " <>
            "effect pairs `entity` (the kind) with `row` (the payload)."
      },
      method: "POST",
      path: "/api/v1/sync/mutations",
      body: %{
        "workspace_id" => workspace_id,
        "device_id" => device_id,
        "mutations" => [
          %{
            "mutation_id" => label(uuid7(), "mutation_id"),
            "entity" => "time_span",
            "op" => "create",
            "payload" => %{
              "id" => label(uuid7(), "span_id"),
              "title" => "Redesign build",
              "client_name" => "Acme",
              "project_name" => "Redesign",
              "start" => "2026-07-27T11:00:00.000000Z",
              "end" => "2026-07-27T12:00:00.000000Z",
              "source" => "timer",
              "is_billable" => true,
              "updated_at" => "2026-07-27T12:00:00.000000Z",
              "origin_device_id" => device_id
            }
          }
        ]
      }
    )

    record(
      conn,
      %{
        "id" => "wire-022",
        "group" => "mutations",
        "name" => "a deferred reference is stored, not rejected",
        "note" =>
          "SYNC-PROTOCOL 6.1 step 2. References are application-level, not database foreign " <>
            "keys, precisely so an at-least-once push queue can deliver a span before the " <>
            "project it names. The write succeeds and the field is reported in " <>
            "unresolved_refs."
      },
      method: "POST",
      path: "/api/v1/sync/mutations",
      body: %{
        "workspace_id" => workspace_id,
        "device_id" => device_id,
        "mutations" => [
          %{
            "mutation_id" => label(uuid7(), "mutation_id"),
            "entity" => "time_span",
            "op" => "create",
            "payload" => %{
              "id" => label(uuid7(), "span_id"),
              "title" => "Work on a project that has not arrived",
              "project_id" => label(uuid7(), "unknown_project_id"),
              "start" => "2026-07-27T13:00:00.000000Z",
              "end" => "2026-07-27T14:00:00.000000Z",
              "source" => "timer",
              "updated_at" => "2026-07-27T14:00:00.000000Z",
              "origin_device_id" => device_id
            }
          }
        ]
      }
    )
  end

  # -- the end null-vs-absent trap -------------------------------------------

  defp end_null_versus_absent(conn, user) do
    workspace_id = label(workspace!(), "workspace_id")
    member!(user.id, workspace_id, "owner")
    device_id = label(uuid7(), "device_id")

    closed = fn label_name ->
      span =
        span!(workspace_id,
          title: "A closed span",
          start_at: ~U[2026-07-27 09:00:00.000000Z],
          end_at: ~U[2026-07-27 10:00:00.000000Z]
        )

      {label(span.id, label_name), span.server_revision}
    end

    {reopen_id, current_revision} = closed.("span_reopen")

    record(
      conn,
      %{
        "id" => "wire-030",
        "group" => "end-null-vs-absent",
        "name" => "\"end\": null with a CURRENT base_revision reopens the span",
        "trap" => true,
        "note" =>
          "Conflict matrix row 7. A user deliberately reopening a span they can currently " <>
            "see is legitimate, so this is applied and the row comes back with end null. " <>
            "Compare wire-031 and wire-032: the SAME field with a different presence or a " <>
            "different base_revision produces three different outcomes."
      },
      method: "POST",
      path: "/api/v1/sync/mutations",
      body: %{
        "workspace_id" => workspace_id,
        "device_id" => device_id,
        "mutations" => [
          %{
            "mutation_id" => label(uuid7(), "mutation_id"),
            "entity" => "time_span",
            "op" => "update",
            "base_revision" => current_revision,
            "payload" => %{
              "id" => reopen_id,
              "title" => "A closed span",
              "start" => "2026-07-27T09:00:00.000000Z",
              "end" => nil,
              "updated_at" => "2026-07-27T18:00:00.000000Z",
              "origin_device_id" => device_id
            }
          }
        ]
      }
    )

    {forbidden_id, stale_revision} = closed.("span_stale_reopen")

    record(
      conn,
      %{
        "id" => "wire-031",
        "group" => "end-null-vs-absent",
        "name" => "\"end\": null with a STALE base_revision is rejected",
        "trap" => true,
        "note" =>
          "Conflict matrix row 6. A closed span is evidence, and a device that has not seen " <>
            "the close must not undo it. base_revision is merely advisory everywhere else in " <>
            "the protocol; here it is DECISIVE, and it is the only thing separating this " <>
            "case from wire-030."
      },
      method: "POST",
      path: "/api/v1/sync/mutations",
      body: %{
        "workspace_id" => workspace_id,
        "device_id" => device_id,
        "mutations" => [
          %{
            "mutation_id" => label(uuid7(), "mutation_id"),
            "entity" => "time_span",
            "op" => "update",
            "base_revision" => stale_revision - 1,
            "payload" => %{
              "id" => forbidden_id,
              "title" => "A closed span",
              "start" => "2026-07-27T09:00:00.000000Z",
              "end" => nil,
              "updated_at" => "2026-07-27T18:00:00.000000Z",
              "origin_device_id" => device_id
            }
          }
        ]
      }
    )

    open_span =
      span!(workspace_id,
        title: "A running timer",
        start_at: ~U[2026-07-27 09:00:00.000000Z],
        end_at: nil,
        # Set so wire-035 can show them surviving a payload that never mentions
        # them.
        is_billable: true,
        client_name: "Acme",
        project_name: "Redesign"
      )

    open_id = label(open_span.id, "span_open")

    record(
      conn,
      %{
        "id" => "wire-033",
        "group" => "end-null-vs-absent",
        "name" => "\"end\": null on a span the SERVER also shows open just applies",
        "trap" => true,
        "note" =>
          "The branch that is easy to fear and is actually harmless. The reopen guard is " <>
            "conditioned on the SERVER's row being closed, not on what the payload says, so a " <>
            "full-document client asserting \"my copy is open\" about a span that IS open never " <>
            "trips it - even from a stale base_revision, as here. Sending explicit null is not " <>
            "in itself a reopen attempt."
      },
      method: "POST",
      path: "/api/v1/sync/mutations",
      body: %{
        "workspace_id" => workspace_id,
        "device_id" => device_id,
        "mutations" => [
          %{
            "mutation_id" => label(uuid7(), "mutation_id"),
            "entity" => "time_span",
            "op" => "update",
            "base_revision" => open_span.server_revision - 1,
            "payload" => %{
              "id" => open_id,
              "title" => "A running timer, retitled",
              "start" => "2026-07-27T09:00:00.000000Z",
              "end" => nil,
              "updated_at" => "2026-07-27T18:00:00.000000Z",
              "origin_device_id" => device_id
            }
          }
        ]
      }
    )

    {merge_id, merge_revision} = closed.("span_omitted_end")

    record(
      conn,
      %{
        "id" => "wire-034",
        "group" => "end-null-vs-absent",
        "name" => "OMITTING `end` on a span closed elsewhere MERGES from a stale base",
        "trap" => true,
        "note" =>
          "The decisive case, and the reason omission is worth the trouble. Same stale " <>
            "base_revision as wire-031, same server-side close - but because `end` is ABSENT " <>
            "rather than null, the reopen guard cannot fire and the edit merges: the title " <>
            "lands and the remote close survives. update is MERGE-ONLY-PRESENT-KEYS " <>
            "(Ecto.Changeset.cast), never a whole-document replace, so an absent key is 'not " <>
            "mentioned' and never 'set to null'. A client that can omit fields can therefore " <>
            "edit a span another device closed; one that always serializes the full document " <>
            "cannot, and gets wire-031 instead. That is a CLIENT capability difference, not a " <>
            "protocol limitation."
      },
      method: "POST",
      path: "/api/v1/sync/mutations",
      body: %{
        "workspace_id" => workspace_id,
        "device_id" => device_id,
        "mutations" => [
          %{
            "mutation_id" => label(uuid7(), "mutation_id"),
            "entity" => "time_span",
            "op" => "update",
            "base_revision" => merge_revision - 1,
            "payload" => %{
              "id" => merge_id,
              "title" => "Retitled from a device that never saw the close",
              "start" => "2026-07-27T09:00:00.000000Z",
              "updated_at" => "2026-07-27T18:00:00.000000Z",
              "origin_device_id" => device_id
            }
          }
        ]
      }
    )

    record(
      conn,
      %{
        "id" => "wire-035",
        "group" => "end-null-vs-absent",
        "name" => "omitted scalar fields are preserved, not nulled",
        "trap" => true,
        "note" =>
          "The general rule behind wire-034, shown on ordinary fields. This payload names " <>
            "only `title`; `is_billable`, `notes` and the resolved client/project names all " <>
            "survive untouched in the response. The rule is uniform across all ten entity " <>
            "kinds - time_span is not special."
      },
      method: "POST",
      path: "/api/v1/sync/mutations",
      body: %{
        "workspace_id" => workspace_id,
        "device_id" => device_id,
        "mutations" => [
          %{
            "mutation_id" => label(uuid7(), "mutation_id"),
            "entity" => "time_span",
            "op" => "update",
            "payload" => %{
              "id" => open_id,
              "title" => "Only the title is being changed",
              "updated_at" => "2026-07-27T19:00:00.000000Z",
              "origin_device_id" => device_id
            }
          }
        ]
      }
    )

    {absent_id, absent_revision} = closed.("span_partial_update")

    record(
      conn,
      %{
        "id" => "wire-032",
        "group" => "end-null-vs-absent",
        "name" => "`end` ABSENT is a partial update and preserves the close",
        "trap" => true,
        "note" =>
          "THE case most likely to be wrong in a client right now. Swift's synthesized " <>
            "Codable and many JSON encoders emit an explicit null for a nil optional, which " <>
            "would turn every partial update into a reopen attempt and trip wire-031's guard " <>
            "on any stale base. Note the response: `end` is still set. An encoder MUST be " <>
            "able to OMIT this key, not merely set it to null."
      },
      method: "POST",
      path: "/api/v1/sync/mutations",
      body: %{
        "workspace_id" => workspace_id,
        "device_id" => device_id,
        "mutations" => [
          %{
            "mutation_id" => label(uuid7(), "mutation_id"),
            "entity" => "time_span",
            "op" => "update",
            "base_revision" => absent_revision,
            "payload" => %{
              "id" => absent_id,
              "title" => "Retitled, but still closed",
              "start" => "2026-07-27T09:00:00.000000Z",
              "updated_at" => "2026-07-27T18:00:00.000000Z",
              "origin_device_id" => device_id
            }
          }
        ]
      }
    )
  end

  # -- conflicts, replays, atomic --------------------------------------------

  defp conflicts_and_replays(conn, user) do
    workspace_id = label(workspace!(), "workspace_id")
    member!(user.id, workspace_id, "owner")
    device_id = label(uuid7(), "device_id")

    acme = label(Canon.client_id(workspace_id, "Acme"), "acme_client_id")

    record(
      conn,
      %{
        "id" => "wire-040",
        "group" => "conflicts",
        "name" => "create a client, id derived from canon(name)",
        "note" =>
          "Taxonomy ids are UUIDv5 derived from the workspace namespace and canon(name), " <>
            "so two offline devices vivifying the same name compute the SAME id and their " <>
            "creates merge with no coordination. canonical_name is server-derived and " <>
            "read-only; a client value for it is ignored."
      },
      method: "POST",
      path: "/api/v1/sync/mutations",
      body: %{
        "workspace_id" => workspace_id,
        "device_id" => device_id,
        "mutations" => [
          %{
            "mutation_id" => label(uuid7(), "mutation_id"),
            "entity" => "client",
            "op" => "create",
            "payload" => %{
              "id" => acme,
              "name" => "Acme",
              "notes" => "",
              "updated_at" => "2026-07-27T09:00:00.000000Z",
              "origin_device_id" => device_id
            }
          }
        ]
      }
    )

    record(
      conn,
      %{
        "id" => "wire-041",
        "group" => "conflicts",
        "name" => "a create whose canonical name is taken is a conflict",
        "trap" => true,
        "note" =>
          "Conflict matrix row 12. Reached after a rename: an offline device vivifies the " <>
            "NEW name, computes a NEW id, and collides. status is `conflict`, and the client " <>
            "MUST adopt the returned entity and rewrite every local reference to it. Note " <>
            "entity_kind is present on a conflict too."
      },
      method: "POST",
      path: "/api/v1/sync/mutations",
      body: %{
        "workspace_id" => workspace_id,
        "device_id" => device_id,
        "mutations" => [
          %{
            "mutation_id" => label(uuid7(), "mutation_id"),
            "entity" => "client",
            "op" => "create",
            "payload" => %{
              "id" => label(uuid7(), "colliding_client_id"),
              "name" => "  ACME  ",
              "updated_at" => "2026-07-27T10:00:00.000000Z",
              "origin_device_id" => device_id
            }
          }
        ]
      }
    )

    screenshot = label(screenshot!(workspace_id).id, "screenshot_id")
    analysis = label(vision_analysis!(workspace_id, screenshot).id, "analysis_id")

    record(
      conn,
      %{
        "id" => "wire-042",
        "group" => "conflicts",
        "name" => "a rejected result: entity is null but entity_kind is present",
        "trap" => true,
        "note" =>
          "Conflict matrix row 14 - vision_analysis is append-only and every update is " <>
            "rejected; re-analysis creates a new row. This is why entity_kind lives on the " <>
            "ENVELOPE rather than inside entity: entity is null here, and the client still " <>
            "has to route the failure back to the mutation it queued."
      },
      method: "POST",
      path: "/api/v1/sync/mutations",
      body: %{
        "workspace_id" => workspace_id,
        "device_id" => device_id,
        "mutations" => [
          %{
            "mutation_id" => label(uuid7(), "mutation_id"),
            "entity" => "vision_analysis",
            "op" => "update",
            "payload" => %{
              "id" => analysis,
              "screenshot_id" => screenshot,
              "status_update" => "rewritten",
              "updated_at" => "2026-07-27T11:00:00.000000Z"
            }
          }
        ]
      }
    )

    replay_mutation_id = label(uuid7(), "replayed_mutation_id")
    replay_span = label(uuid7(), "replayed_span_id")

    replay_body = %{
      "workspace_id" => workspace_id,
      "device_id" => device_id,
      "mutations" => [
        %{
          "mutation_id" => replay_mutation_id,
          "entity" => "time_span",
          "op" => "create",
          "payload" => %{
            "id" => replay_span,
            "title" => "Delivered twice",
            "start" => "2026-07-27T14:00:00.000000Z",
            "end" => "2026-07-27T15:00:00.000000Z",
            "source" => "timer",
            "updated_at" => "2026-07-27T15:00:00.000000Z",
            "origin_device_id" => device_id
          }
        }
      ]
    }

    record(
      conn,
      %{
        "id" => "wire-043",
        "group" => "conflicts",
        "name" => "first delivery of a mutation",
        "note" => "Compare wire-044, which is the identical request delivered a second time."
      },
      method: "POST",
      path: "/api/v1/sync/mutations",
      body: replay_body
    )

    record(
      conn,
      %{
        "id" => "wire-044",
        "group" => "conflicts",
        "name" => "replay returns the ORIGINAL result with replayed true",
        "trap" => true,
        "note" =>
          "The push queue is at-least-once, so duplicate delivery is expected rather than " <>
            "exceptional. The server answers from the mutation ledger: identical to wire-043 " <>
            "in every field except `replayed`, INCLUDING server_revision. It does not " <>
            "re-apply, does not bump the revision, and does not re-run duplicate detection - " <>
            "re-deriving the answer would be wrong, not merely wasteful, because the row has " <>
            "usually moved on."
      },
      method: "POST",
      path: "/api/v1/sync/mutations",
      body: replay_body
    )

    locked =
      label(
        span!(workspace_id, title: "An approved day", locked_at: ~U[2026-07-26 23:00:00.000000Z]).id,
        "locked_span_id"
      )

    record(
      conn,
      %{
        "id" => "wire-045",
        "group" => "conflicts",
        "name" => "an atomic batch rolls back whole and answers 409",
        "trap" => true,
        "note" =>
          "Conflict matrix row 22. HTTP 409, and EVERY result is rejected/batch_rolled_back " <>
            "- including the member that would have succeeded on its own. Nothing was " <>
            "written. This is what makes split and merge, expressed as ordinary create/" <>
            "update/delete mutations sharing a derived_from_span_ids lineage, land whole or " <>
            "not at all. entity_kind is still carried on each result so the client can map " <>
            "them back to its queue."
      },
      method: "POST",
      path: "/api/v1/sync/mutations",
      body: %{
        "workspace_id" => workspace_id,
        "device_id" => device_id,
        "atomic" => true,
        "mutations" => [
          %{
            "mutation_id" => label(uuid7(), "mutation_id"),
            "entity" => "time_span",
            "op" => "create",
            "payload" => %{
              "id" => label(uuid7(), "rolled_back_span_id"),
              "title" => "Would have been fine on its own",
              "start" => "2026-07-27T16:00:00.000000Z",
              "end" => "2026-07-27T17:00:00.000000Z",
              "source" => "manual",
              "updated_at" => "2026-07-27T17:00:00.000000Z",
              "origin_device_id" => device_id
            }
          },
          %{
            "mutation_id" => label(uuid7(), "mutation_id"),
            "entity" => "time_span",
            "op" => "update",
            "payload" => %{
              "id" => locked,
              "title" => "Editing a locked day",
              "start" => "2026-07-26T09:00:00.000000Z",
              "updated_at" => "2026-07-27T17:00:00.000000Z",
              "origin_device_id" => device_id
            }
          }
        ]
      }
    )

    record(
      conn,
      %{
        "id" => "wire-046",
        "group" => "conflicts",
        "name" => "an unknown entity kind yields a null entity_kind",
        "note" =>
          "entity_kind echoes only values inside the EntityKind enum. An unrecognised kind " <>
            "comes back null rather than reflecting the client's own bad string back at it."
      },
      method: "POST",
      path: "/api/v1/sync/mutations",
      body: %{
        "workspace_id" => workspace_id,
        "device_id" => device_id,
        "mutations" => [
          %{
            "mutation_id" => label(uuid7(), "mutation_id"),
            "entity" => "wormhole",
            "op" => "create",
            "payload" => %{"id" => label(uuid7(), "unknown_kind_id")}
          }
        ]
      }
    )
  end

  # -- settings ---------------------------------------------------------------

  defp settings(conn, user) do
    workspace_id = label(workspace!(), "workspace_id")
    member!(user.id, workspace_id, "owner")
    device_id = label(uuid7(), "device_id")
    label(user.id, "user_id")

    record(
      conn,
      %{
        "id" => "wire-050",
        "group" => "settings",
        "name" => "user_settings is FLATTENED, with no nested document",
        "trap" => true,
        "note" =>
          "The server stores this body in a `document` jsonb column, but the wire shape " <>
            "merges it to top level under the `kind` discriminator. There is NO nested " <>
            "`document` key in either direction. Contract defaults are merged underneath, so " <>
            "a row written before a field existed still reads as a complete document - note " <>
            "the fields present in the response that the request never sent."
      },
      method: "POST",
      path: "/api/v1/sync/mutations",
      body: %{
        "workspace_id" => workspace_id,
        "device_id" => device_id,
        "mutations" => [
          %{
            "mutation_id" => label(uuid7(), "mutation_id"),
            "entity" => "user_settings",
            "op" => "update",
            "payload" => %{
              "id" => label(Canon.user_settings_id(workspace_id, user.id), "user_settings_id"),
              "kind" => "user_settings",
              "user_id" => user.id,
              "pomodoro_work_minutes" => 50,
              "idle_threshold_minutes" => 10,
              "updated_at" => "2026-07-27T09:00:00.000000Z",
              "origin_device_id" => device_id
            }
          }
        ]
      }
    )

    record(
      conn,
      %{
        "id" => "wire-051",
        "group" => "settings",
        "name" => "workspace_policy is flattened the same way",
        "trap" => true,
        "note" =>
          "user_settings and workspace_policy are two EntityKinds over one table and one " <>
            "`settings` bucket, discriminated by `kind`. That is also why entity_kind lives " <>
            "on the mutation-result envelope: SettingsRow already uses `kind` for this, so an " <>
            "in-row discriminator would be doing double duty. Only an admin may write this " <>
            "(conflict matrix row 19)."
      },
      method: "POST",
      path: "/api/v1/sync/mutations",
      body: %{
        "workspace_id" => workspace_id,
        "device_id" => device_id,
        "mutations" => [
          %{
            "mutation_id" => label(uuid7(), "mutation_id"),
            "entity" => "workspace_policy",
            "op" => "update",
            "payload" => %{
              "id" => workspace_id,
              "kind" => "workspace_policy",
              "screenshot_upload_allowed" => true,
              "sync_vision_raw_response" => false,
              "updated_at" => "2026-07-27T09:30:00.000000Z",
              "origin_device_id" => device_id
            }
          }
        ]
      }
    )
  end

  # -- screenshots and blobs --------------------------------------------------

  defp screenshots(conn, user) do
    workspace_id = label(workspace!(), "workspace_id")
    member!(user.id, workspace_id, "owner")
    device_id = label(uuid7(), "device_id")
    screenshot_id = label(uuid7(), "screenshot_id")

    {:ok, _} =
      Timely.Sync.Devices.register(workspace_id, user.id, %{
        "device_id" => device_id,
        "platform" => "macos",
        "name" => "Capture agent",
        "app_version" => "1.0.0"
      })

    record(
      conn,
      %{
        "id" => "wire-060",
        "group" => "screenshots",
        "name" => "server-owned screenshot fields are IGNORED, not rejected",
        "trap" => true,
        "note" =>
          "Conflict matrix row 17. This request sets upload_state, blob_content_hash, " <>
            "blob_byte_size and blob_available; the mutation is APPLIED and every one of " <>
            "them is discarded. blob_available in particular is DERIVED (upload_state == " <>
            "\"uploaded\"), never stored and never accepted as input. Compare the response: " <>
            "upload_state is local_only and the blob_* fields are null."
      },
      method: "POST",
      path: "/api/v1/sync/mutations",
      body: %{
        "workspace_id" => workspace_id,
        "device_id" => device_id,
        "mutations" => [
          %{
            "mutation_id" => label(uuid7(), "mutation_id"),
            "entity" => "screenshot",
            "op" => "create",
            "payload" => %{
              "id" => screenshot_id,
              "captured_at" => "2026-07-27T09:15:00.000000Z",
              "file_name" => "timely-20260727-091500.png",
              "active_app_name" => "Xcode",
              "upload_state" => "uploaded",
              "blob_available" => true,
              "blob_content_hash" => String.duplicate("a", 64),
              "blob_byte_size" => 999_999,
              "updated_at" => "2026-07-27T09:15:00.000000Z",
              "origin_device_id" => device_id
            }
          }
        ]
      }
    )

    record(
      conn,
      %{
        "id" => "wire-061",
        "group" => "screenshots",
        "name" => "screenshot metadata, the byte-free recall surface",
        "note" =>
          "Metadata ALWAYS syncs; bytes do not. This is what a companion renders for a " <>
            "local-only capture: captured_at, active_app_name, the owning span, and the " <>
            "origin device. file_name is advisory provenance only and is NOT unique - the " <>
            "macOS agent formats it at second resolution, so two captures in one second " <>
            "collide. Nothing may key on it."
      },
      method: "GET",
      path: "/api/v1/screenshots/#{screenshot_id}"
    )

    record(
      conn,
      %{
        "id" => "wire-062",
        "group" => "screenshots",
        "name" => "blob upload refused: both gates closed",
        "trap" => true,
        "note" =>
          "409 with a `gates` object naming WHICH side is closed, so the user can be told " <>
            "what to change. The gate is workspace_policy.screenshot_upload_allowed AND " <>
            "device.local_only_screenshots == false; both default to the privacy-preserving " <>
            "value. The rejected body is not buffered, quarantined or retained."
      },
      method: "POST",
      path: "/api/v1/screenshots/#{screenshot_id}/blob",
      headers: %{"x-timely-device-id" => device_id, "content-type" => "image/png"},
      raw_body: "PNGBYTES"
    )

    record(
      conn,
      %{
        "id" => "wire-063",
        "group" => "screenshots",
        "name" => "blob download of a local-only screenshot is 404 - the NORMAL path",
        "trap" => true,
        "note" =>
          "404 blob_not_available is the ordinary case for most screenshots, not an error. " <>
            "Clients MUST treat it as unremarkable and render the metadata-only surface from " <>
            "wire-061 instead. Surfacing it to the user as a failure is a bug."
      },
      method: "GET",
      path: "/api/v1/screenshots/#{screenshot_id}/blob"
    )

    set_policy!(workspace_id, %{"screenshot_upload_allowed" => true})
    {:ok, _} = Timely.Sync.Devices.update(workspace_id, user.id, device_id, %{"local_only_screenshots" => false})

    record(
      conn,
      %{
        "id" => "wire-064",
        "group" => "screenshots",
        "name" => "blob upload accepted once BOTH gates are open",
        "note" =>
          "201. upload_state becomes uploaded and server_revision is bumped, so the metadata " <>
            "change reaches other devices through the ordinary pull loop rather than needing " <>
            "its own channel."
      },
      method: "POST",
      path: "/api/v1/screenshots/#{screenshot_id}/blob",
      headers: %{"x-timely-device-id" => device_id, "content-type" => "image/png"},
      raw_body: "PNGBYTES"
    )

    record(
      conn,
      %{
        "id" => "wire-065",
        "group" => "screenshots",
        "name" => "blob download returns image bytes, not JSON",
        "note" =>
          "The only non-JSON response in the API. The fixture records the content type and " <>
            "byte length rather than the bytes themselves."
      },
      method: "GET",
      path: "/api/v1/screenshots/#{screenshot_id}/blob"
    )

    record(
      conn,
      %{
        "id" => "wire-066",
        "group" => "screenshots",
        "name" => "blob_available is now true, still derived",
        "trap" => true,
        "note" =>
          "Same row as wire-061, after the upload. blob_available flipped without any client " <>
            "ever setting it: it is computed from upload_state on every read. A client that " <>
            "persists it as stored state will go stale."
      },
      method: "GET",
      path: "/api/v1/screenshots/#{screenshot_id}"
    )
  end

  # -- reports ----------------------------------------------------------------

  defp reports(conn, user) do
    workspace_id = label(workspace!(), "workspace_id")
    member!(user.id, workspace_id, "owner")

    project_id = label(uuid7(), "project_id")

    label(
      span!(workspace_id,
        title: "Redesign build",
        project_id: project_id,
        project_name: "Redesign",
        client_name: "Acme",
        is_billable: true,
        start_at: ~U[2026-07-27 09:00:00.000000Z],
        end_at: ~U[2026-07-27 10:45:00.000000Z]
      ).id,
      "span_a"
    )

    label(
      span!(workspace_id,
        title: "Client call",
        project_id: project_id,
        project_name: "Redesign",
        client_name: "Acme",
        is_billable: true,
        start_at: ~U[2026-07-27 09:55:00.000000Z],
        end_at: ~U[2026-07-27 10:45:00.000000Z]
      ).id,
      "span_b"
    )

    record(
      conn,
      %{
        "id" => "wire-070",
        "group" => "reports",
        "name" => "summary with overlapping billable work",
        "trap" => true,
        "note" =>
          "Four time figures are reported separately because conflating them is a " <>
            "credibility risk. These two spans overlap by 50 minutes: elapsed_seconds counts " <>
            "each span in full and therefore EXCEEDS wall-clock time, which is correct - " <>
            "parallel work is the product. weighted_billable_seconds splits every contested " <>
            "instant evenly, so summing it across groups never exceeds wall clock, and the " <>
            "overlap cannot be billed twice."
      },
      method: "GET",
      path: "/api/v1/reports/summary",
      query: %{
        "workspace_id" => workspace_id,
        "from" => "2026-07-27T00:00:00Z",
        "to" => "2026-07-28T00:00:00Z",
        "group_by" => "project"
      }
    )

    record(
      conn,
      %{
        "id" => "wire-071",
        "group" => "reports",
        "name" => "summary grouped by day in an IANA time zone",
        "note" =>
          "group_by=day buckets in the caller's zone, not UTC. Spans with no project roll " <>
            "up under \"Unassigned\" rather than being dropped - the time was still worked."
      },
      method: "GET",
      path: "/api/v1/reports/summary",
      query: %{
        "workspace_id" => workspace_id,
        "from" => "2026-07-27T00:00:00Z",
        "to" => "2026-07-28T00:00:00Z",
        "group_by" => "day",
        "time_zone" => "America/Chicago"
      }
    )
  end

  # ---------------------------------------------------------------------------
  # Document header
  # ---------------------------------------------------------------------------

  defp document(cases, placeholders) do
    %{
      "$schema_note" => "Plain JSON. No external schema. Consumed directly by test suites.",
      "title" => "Timely wire-format conformance fixtures",
      "version" => "1.0.0",
      "generated_for_contract_version" => "1.0.0-draft.1",
      "about" => [
        "Recorded request/response pairs captured from the running Elixir server by driving",
        "the real Phoenix router. Every response body in this file is what the server actually",
        "emitted, never a hand-written description of what it is believed to emit.",
        "",
        "These pin the contract-level semantics that an OpenAPI schema cannot express: which",
        "fields are server-owned and silently ignored, which are derived rather than stored,",
        "and - most importantly - where the difference between a null value and an ABSENT key",
        "changes the server's behaviour.",
        "",
        "Cases marked \"trap\": true are the ones a client is most likely to get wrong. They",
        "are not edge cases; each corresponds to a mistake already made at least once in this",
        "project's own implementations.",
        "",
        "A backend test regenerates this file and compares it to the committed copy on every",
        "run, so it cannot drift from the server without failing CI."
      ],
      "how_to_consume" => [
        "Swift and Kotlin: load this file at test time, and for each case assert your codec",
        "round-trips it. There is no server involved and no network required.",
        "",
        "1. ENCODE: build the case's `request.body` with your own request types and assert your",
        "   serialized JSON equals it - after applying the same normalization described below.",
        "   Key PRESENCE must match exactly. A codec that emits \"end\": null where the fixture",
        "   omits the key fails wire-032, which is the intended behaviour: that bug turns every",
        "   partial span update into a reopen attempt.",
        "",
        "2. DECODE: parse the case's `response.body` into your model types and assert no field",
        "   is lost. Decoding MUST NOT fail on unknown fields - the server adds fields without a",
        "   major version bump.",
        "",
        "3. Assert the documented outcome. `response.status` and, for mutations,",
        "   `results[].status` / `.reason` / `.entity_kind` are the contract; the `note` on each",
        "   case says why.",
        "",
        "Do not hand-edit this file. Regenerate it with gen-wire-fixtures.sh and commit the",
        "result, the same way canon-fixtures.json is produced."
      ],
      "normalization" => [
        "Values that differ between runs are replaced with placeholders IN PLACE. No key is",
        "ever added or removed by normalization - presence and absence are the payload here,",
        "so a normalizer that dropped nulls would erase the very distinction being pinned.",
        "",
        "  @timestamp  - an ISO 8601 instant chosen at run time.",
        "  @uuid       - a server-minted id the scenario did not name.",
        "  @<name>     - a labelled id. The SAME placeholder in a request and a response means",
        "                the SAME id, so relationships stay legible: a mutation's payload.id",
        "                appearing as the entity's id, or a conflict returning a DIFFERENT id",
        "                than the one that was sent.",
        "",
        "Integers are left alone. server_revision, next_cursor and base_revision are real",
        "values and their relative ordering within a case is part of what is being asserted.",
        "",
        "Fixed instants inside request bodies (2026-07-27T09:00:00Z and similar) are literal:",
        "they are inputs the scenario chose, not captured output."
      ],
      "placeholders" => placeholders,
      "traps" => [
        "wire-030..035 - `\"end\": null` vs `end` ABSENT, the distinction a JSON schema cannot",
        "  express. What decides the outcome is the SERVER's row plus base_revision, not the",
        "  payload alone:",
        "    wire-033  null + server row OPEN            -> applies; the guard never fires,",
        "                                                   stale base_revision or not.",
        "    wire-030  null + server CLOSED + base CURRENT -> applied as a deliberate reopen (row 7).",
        "    wire-031  null + server CLOSED + base STALE   -> rejected span_reopen_forbidden (row 6).",
        "    wire-032  absent + server CLOSED             -> partial update; the close is PRESERVED.",
        "    wire-034  absent + server CLOSED + base STALE -> MERGES. The title lands and the",
        "                                                   remote close survives - the case a",
        "                                                   full-document client cannot express.",
        "wire-032/034 - the single most likely live bug, because synthesized Codable and many",
        "  JSON encoders emit explicit null for a nil optional by default. A client that can only",
        "  emit null gets wire-031 where one that can OMIT gets wire-034. That is a client",
        "  capability difference, not a protocol limitation.",
        "wire-035 - update is MERGE-ONLY-PRESENT-KEYS (Ecto.Changeset.cast), never a",
        "  whole-document replace. An absent key is 'not mentioned', never 'set to null', and the",
        "  rule is uniform across all ten entity kinds. The exceptions are envelope fields the",
        "  server owns outright: updated_at, updated_at_effective, server_revision, deleted_at,",
        "  and origin_device_id, which falls back to the PUSHING device because it means 'who",
        "  last authored this row' and is the LWW tie-break key.",
        "wire-050/051 - SettingsRow is FLATTENED. The document is merged to top level under the",
        "  `kind` discriminator; there is no nested `document` key on the wire.",
        "wire-060/066 - screenshot.blob_available is DERIVED from upload_state, never stored and",
        "  never accepted as input, along with upload_state and every blob_* field (row 17).",
        "  They are ignored rather than rejected, so a client gets no error to notice.",
        "wire-042 - entity_kind is on the RESULT ENVELOPE and is present even when entity is",
        "  null, which is exactly when a client most needs to route the failure back to its",
        "  queue. Results arrive in one flat array; nothing else identifies the row's type.",
        "wire-020 - wire names are `start` and `end`. The SQL columns are start_at/end_at and",
        "  must never appear on the wire; a client sending start_at will have it ignored.",
        "wire-041 - a create can come back as a `conflict` carrying a DIFFERENT id than the one",
        "  sent. The client must adopt it and rewrite local references.",
        "wire-044 - a replay returns the ORIGINAL result, server_revision included.",
        "wire-045 - an atomic 409 rejects EVERY member, including ones that would have applied.",
        "wire-062/063 - the screenshot double gate, and 404 as the normal download path.",
        "wire-070 - elapsed_seconds may legitimately exceed wall-clock time; only",
        "  weighted_billable_seconds is overlap-corrected."
      ],
      "cases" => cases
    }
  end
end
