#!/usr/bin/env bash
#
# verify-age-stack.sh — turnkey Apache AGE verification for The Robot Remembers.
#
# Stands up a throwaway AGE-capable Postgres (the production DB image), applies the full Liquibase
# changelog through 031 (the AGE graph), then runs the live verification that CANNOT run against
# the AGE-less shared dev/CI Postgres:
#
#   1. db-up / db-ready . the verify Postgres boots and accepts connections
#   2. liquibase ........ changelog 000..031 applies cleanly (incl. CREATE EXTENSION age +
#                         create_graph('trr_memory') + all label/index DDL)
#   3. age-roundtrip .... the `age` extension is installed and the trr_memory graph is queryable
#   4. mix-test-age ..... `mix test --include age` — full suite plus the live :age suites
#                         (GraphMirror round-trip, GraphBench overlap + stats)
#   5. bench-smoke ...... `mix trr.bench.graph` on a tiny synthetic graph, with cleanup
#
# It never touches the dev stack: its own compose project (trr-age-verify), its own host port
# (5499), and its own named volume.
#
# Usage:
#   scripts/verify-age-stack.sh          full verification; tear the stack down on success
#   scripts/verify-age-stack.sh --keep   full verification; leave the DB container running
#   scripts/verify-age-stack.sh --down   tear the verify stack down and exit (no verification)
#
# Requires Docker access. If your shell is not in the `docker` group, run under sudo or add the
# group (`sudo usermod -aG docker "$USER"` then re-login). mix runs on the host (asdf toolchain,
# see .tool-versions); it needs hex access for `mix deps.get` on a fresh checkout.
#
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${APP_DIR}"

COMPOSE_FILE="docker-compose.age-verify.yaml"
# Force the project name: app/.env sets COMPOSE_PROJECT_NAME=therobotremembers, which would
# otherwise override the compose `name:` and share the dev stack's project. `-p` has the highest
# precedence, guaranteeing the verify stack lives in its own isolated project/network/volumes.
COMPOSE_PROJECT="trr-age-verify"
DB_SERVICE="age-verify-db"
MIGRATIONS_SERVICE="age-verify-migrations"

# Verify DB coordinates (override via environment). VERIFY_DB_NAME is the *physical* database and
# the Liquibase target; mix is pointed at MIX_DB_NAME because config/test.exs appends "_test".
export VERIFY_DB_USER="${VERIFY_DB_USER:-trr_verify}"
export VERIFY_DB_PASSWORD="${VERIFY_DB_PASSWORD:-trr_verify_pw}"
export VERIFY_DB_NAME="${VERIFY_DB_NAME:-trr_verify_test}"
export VERIFY_DB_PORT="${VERIFY_DB_PORT:-5499}"
MIX_DB_NAME="trr_verify" # config/test.exs => "${MIX_DB_NAME}_test" == VERIFY_DB_NAME

KEEP=false
DOWN_ONLY=false
for arg in "$@"; do
  case "${arg}" in
    --keep) KEEP=true ;;
    --down) DOWN_ONLY=true ;;
    -h | --help)
      sed -n '2,32p' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    *)
      echo "unknown flag: ${arg} (see --help)" >&2
      exit 2
      ;;
  esac
done

if [[ -t 1 ]]; then
  c_green="$(printf '\033[32m')"; c_red="$(printf '\033[31m')"
  c_cyan="$(printf '\033[36m')"; c_reset="$(printf '\033[0m')"
else
  c_green=""; c_red=""; c_cyan=""; c_reset=""
fi
say()  { printf '%s==>%s %s\n' "${c_cyan}" "${c_reset}" "$*"; }
pass() { printf '%sPASS%s %s\n' "${c_green}" "${c_reset}" "$*"; }
die()  { printf '%sFAIL%s %s\n' "${c_red}" "${c_reset}" "$*" >&2; exit 1; }

compose() { docker compose -p "${COMPOSE_PROJECT}" -f "${COMPOSE_FILE}" "$@"; }
teardown() {
  say "tearing down verify stack"
  compose down -v --remove-orphans || true
}

if [[ "${DOWN_ONLY}" == true ]]; then
  teardown
  pass "verify stack removed"
  exit 0
fi

command -v docker >/dev/null 2>&1 || die "docker CLI not found on PATH"
docker info >/dev/null 2>&1 ||
  die "cannot reach the Docker daemon — add your user to the 'docker' group or run under sudo"

STAGE="startup"
on_err() {
  printf '\n%sFAIL%s during stage: %s\n' "${c_red}" "${c_reset}" "${STAGE}" >&2
  printf 'The verify stack was left running for inspection. Remove it with:\n' >&2
  printf '  scripts/verify-age-stack.sh --down\n' >&2
}
trap on_err ERR

# ── 1. bring up the AGE database ─────────────────────────────────
STAGE="db-up"
say "starting ${DB_SERVICE} (${VERIFY_DB_NAME} on host port ${VERIFY_DB_PORT})"
compose up -d "${DB_SERVICE}"

STAGE="db-ready"
say "waiting for Postgres to accept connections"
for i in $(seq 1 60); do
  if compose exec -T "${DB_SERVICE}" pg_isready -U "${VERIFY_DB_USER}" -d "${VERIFY_DB_NAME}" >/dev/null 2>&1; then
    break
  fi
  if [[ "${i}" -eq 60 ]]; then die "database did not become ready within ~120s"; fi
  sleep 2
done
pass "database ready"

# ── 2. Liquibase through 031 ─────────────────────────────────────
STAGE="liquibase"
say "applying Liquibase changelog 000..031 (incl. AGE graph)"
compose run --rm "${MIGRATIONS_SERVICE}"
pass "liquibase update completed"

# ── 3. AGE round-trip ────────────────────────────────────────────
STAGE="age-roundtrip"
say "checking the age extension and the trr_memory graph"
psql_q() {
  compose exec -T "${DB_SERVICE}" \
    psql -tAX -U "${VERIFY_DB_USER}" -d "${VERIFY_DB_NAME}" -c "$1" | tr -d '[:space:]'
}
age_ver="$(psql_q "SELECT extversion FROM pg_extension WHERE extname='age';")"
[[ -n "${age_ver}" ]] || die "age extension not installed (expected via Liquibase 031)"
graph_ct="$(psql_q "SELECT count(*) FROM ag_catalog.ag_graph WHERE name='trr_memory';")"
[[ "${graph_ct}" == "1" ]] || die "trr_memory graph not found (ag_graph count=${graph_ct})"
pass "age ${age_ver} installed; trr_memory graph present"

# ── 4/5. run mix against the verify DB ───────────────────────────
# Ecto reads DB_PASS (Liquibase read DB_PASSWORD); config/test.exs turns DB_NAME into
# "${DB_NAME}_test", which resolves to VERIFY_DB_NAME.
export DB_HOST="localhost"
export DB_PORT="${VERIFY_DB_PORT}"
export DB_USER="${VERIFY_DB_USER}"
export DB_PASS="${VERIFY_DB_PASSWORD}"
export DB_NAME="${MIX_DB_NAME}"
export AGE_GRAPH_ENABLED="true"
export MIX_ENV="test"

cd "${APP_DIR}/backend"

STAGE="deps"
say "mix deps.get"
mix deps.get >/dev/null

STAGE="mix-test-age"
say "mix test --include age (full suite + live :age suites)"
mix test --include age
pass "mix test --include age green"

STAGE="bench-smoke"
say "bench smoke: mix trr.bench.graph (1000 nodes / 3000 edges)"
mix trr.bench.graph --nodes 1000 --edges 3000 --queries 5 --seed-size 10
pass "bench smoke completed (CTE + AGE traversal, cleaned up)"

cd "${APP_DIR}"
trap - ERR

# ── summary ──────────────────────────────────────────────────────
printf '\n%s==== AGE STACK VERIFICATION: PASS ====%s\n' "${c_green}" "${c_reset}"
printf '  liquibase 031 ......... ok\n'
printf '  age %-17s ok\n' "${age_ver}"
printf '  mix test --include age  ok\n'
printf '  bench smoke ........... ok\n'

if [[ "${KEEP}" == true ]]; then
  printf '\nDB left running (--keep): postgresql://%s@localhost:%s/%s\n' \
    "${VERIFY_DB_USER}" "${VERIFY_DB_PORT}" "${VERIFY_DB_NAME}"
  printf 'Full Phase-C benchmark against it:\n'
  printf '  cd backend && DB_HOST=localhost DB_PORT=%s DB_USER=%s DB_PASS=*** DB_NAME=%s \\\n' \
    "${VERIFY_DB_PORT}" "${VERIFY_DB_USER}" "${MIX_DB_NAME}"
  printf '    AGE_GRAPH_ENABLED=true MIX_ENV=test mix trr.bench.graph --scale-sweep --queries 50 --seed-size 40\n'
  printf 'Remove when done:  scripts/verify-age-stack.sh --down\n'
else
  teardown
  pass "verify stack removed (pass --keep to retain it next time)"
fi
