#!/usr/bin/env bash
#
# Regenerate wire-fixtures.json from the running Elixir server.
#
# Unlike gen-canon-fixtures.py, which reimplements canon() as a reference, this
# generator has no reference implementation of its own and cannot have one: the
# whole point of the file is that it is a TRANSCRIPT of what the server actually
# emits. It works by driving the real Phoenix router through Phoenix.ConnTest
# and recording the serialized responses.
#
# Generation and verification are the same code path
# (apps/backend/test/timely/sync/wire_fixtures_test.exs). Running the backend
# suite normally REGENERATES the fixtures in memory and asserts they match the
# committed file, so it cannot silently drift from the server. This script only
# adds WIRE_FIXTURES=overwrite, which writes the new capture to disk.
#
# Requires the backend test database (see apps/backend/README or docker-compose).
#
# Usage:
#   apps/shared/contracts/gen-wire-fixtures.sh
#   git diff apps/shared/contracts/wire-fixtures.json   # ALWAYS review this
#
# The Swift and Kotlin suites assert against this file, so a diff here is a
# change to their contract. Never hand-edit the JSON.

set -euo pipefail

backend="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../backend" && pwd)"

if ! command -v mix >/dev/null 2>&1; then
  echo "error: mix is not on PATH." >&2
  echo "This generator drives the real Elixir server; it cannot run without the" >&2
  echo "backend toolchain. If you use asdf, the shims are usually at" >&2
  echo "  export PATH=\"\$HOME/.config/asdf/shims:\$PATH\"" >&2
  exit 127
fi

cd "$backend"

MIX_ENV=test WIRE_FIXTURES=overwrite \
  mix test test/timely/sync/wire_fixtures_test.exs "$@"

echo
echo "Regenerated apps/shared/contracts/wire-fixtures.json"
echo "Review the diff before committing - it changes the client contract."
