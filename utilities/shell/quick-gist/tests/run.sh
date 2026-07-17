#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$ROOT/quick-gist"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/quick-gist-test.XXXXXX")"
PASS=0
FAIL=0
trap 'rm -rf "$TEST_ROOT"' EXIT

mkdir -p "$TEST_ROOT/bin"

cat >"$TEST_ROOT/bin/gh" <<'MOCK'
#!/usr/bin/env bash
set -u
printf '%q ' "$@" >>"$GH_TEST_LOG"
printf '\n' >>"$GH_TEST_LOG"
case "${1:-} ${2:-}" in
  'auth status')
    printf 'github.com\n  ✓ Logged in to github.com account test-user (keyring)\n'
    ;;
  'auth token')
    [[ " $* " == *' --user org-name '* ]] && { echo 'not a stored personal account' >&2; exit 1; }
    printf 'test-token\n'
    ;;
  'api user')
    if [[ "${GH_ENV_INVALID:-0}" == 1 && "${GH_TOKEN:-}" != test-token ]]; then echo 'bad environment token' >&2; exit 1; fi
    printf 'test-user\n'
    ;;
  'gist create')
    if [[ "${GH_FAIL_CREATE:-0}" == 1 ]]; then echo 'API: payload too large (HTTP 422)' >&2; exit 1; fi
    previous=''
    for argument in "$@"; do
      if [[ "$previous" == --desc ]]; then printf '%s' "$argument" >"$GH_TEST_LOG.description"; break; fi
      previous="$argument"
    done
    printf 'https://gist.github.com/test-user/abc123\n'
    ;;
  'gist edit')
    edit_count_file="${GH_TEST_LOG}.edits"
    count=0; [[ -f "$edit_count_file" ]] && count="$(cat "$edit_count_file")"
    count=$((count + 1)); printf '%s' "$count" >"$edit_count_file"
    if [[ "${GH_FAIL_EDIT_AT:-0}" == "$count" ]]; then echo 'API: update rejected' >&2; exit 1; fi
    ;;
  'gist list') printf 'abc123  example gist\n' ;;
  'gist view') ;;
  *) echo "unexpected gh invocation: $*" >&2; exit 90 ;;
esac
MOCK
chmod +x "$TEST_ROOT/bin/gh"

cat >"$TEST_ROOT/bin/fzf" <<'MOCK'
#!/usr/bin/env bash
cat
MOCK
chmod +x "$TEST_ROOT/bin/fzf"

run_case() {
    local name="$1" expected="$2"
    shift 2
    local dir="$TEST_ROOT/case-$name" output status
    mkdir -p "$dir"
    : >"$dir/gh.log"
    output="$(cd "$dir" && PATH="$TEST_ROOT/bin:$PATH" GH_TEST_LOG="$dir/gh.log" NO_COLOR=1 "$@" 2>&1)"
    status=$?
    if [[ "$status" == "$expected" ]]; then
        PASS=$((PASS + 1))
        printf 'ok - %s\n' "$name"
    else
        FAIL=$((FAIL + 1))
        printf 'not ok - %s (wanted %s, got %s)\n%s\n' "$name" "$expected" "$status" "$output"
    fi
    CASE_DIR="$dir"
    CASE_OUTPUT="$output"
}

assert_contains() {
    local name="$1" haystack="$2" needle="$3"
    if [[ "$haystack" == *"$needle"* ]]; then
        PASS=$((PASS + 1)); printf 'ok - %s\n' "$name"
    else
        FAIL=$((FAIL + 1)); printf 'not ok - %s (missing: %s)\n' "$name" "$needle"
    fi
}

assert_equals() {
    local name="$1" actual="$2" expected="$3"
    if [[ "$actual" == "$expected" ]]; then
        PASS=$((PASS + 1)); printf 'ok - %s\n' "$name"
    else
        FAIL=$((FAIL + 1)); printf 'not ok - %s (wanted: %s, got: %s)\n' "$name" "$expected" "$actual"
    fi
}

case_dir="$TEST_ROOT/setup-success"; mkdir -p "$case_dir"; printf 'one\n' >"$case_dir/a.txt"; printf 'two\n' >"$case_dir/b.txt"
run_case create-success 0 "$SCRIPT" -d test "$case_dir/a.txt" "$case_dir/b.txt"
assert_contains create-confirms "$CASE_OUTPUT" 'Created successfully'
assert_contains create-owner "$CASE_OUTPUT" 'Owner:      @test-user'
assert_contains create-progress "$(cat "$CASE_DIR/gh.log")" 'gist edit'
assert_equals create-description-attribution "$(cat "$CASE_DIR/gh.log.description")" 'test -- pushed with [quick-gist](https://github.com/noizu/quick-gist)'

case_dir="$TEST_ROOT/setup-default-description"; mkdir -p "$case_dir"; printf 'one\n' >"$case_dir/a.txt"
run_case create-default-description 0 "$SCRIPT" "$case_dir/a.txt"
assert_equals default-description-attribution "$(cat "$CASE_DIR/gh.log.description")" '-- pushed with [quick-gist](https://github.com/noizu/quick-gist)'

case_dir="$TEST_ROOT/setup-fail"; mkdir -p "$case_dir"; printf 'one\n' >"$case_dir/a.txt"
run_case create-failure 1 env GH_FAIL_CREATE=1 "$SCRIPT" -d test "$case_dir/a.txt"
assert_contains failure-is-explicit "$CASE_OUTPUT" 'Gist creation failed; no success was reported.'
assert_contains failure-is-not-green "$CASE_OUTPUT" 'payload too large'

case_dir="$TEST_ROOT/setup-chunk"; mkdir -p "$case_dir"; printf '123456789\n123456789\n123456789\n' >"$case_dir/large.log"
run_case large-file-chunking 0 "$SCRIPT" -d test --chunk-size 10 "$case_dir/large.log"
assert_contains chunk-reported "$CASE_OUTPUT" 'upload-safe parts'
assert_contains chunk-count "$CASE_OUTPUT" 'Files:      3'

case_dir="$TEST_ROOT/setup-filter"; mkdir -p "$case_dir"; printf '# sh\n' >"$case_dir/yes.sh"; printf 'no\n' >"$case_dir/no.txt"
run_case extension-filter 0 "$SCRIPT" -d test -x sh "$case_dir"
assert_contains extension-included "$(cat "$CASE_DIR/gh.log")" 'yes.sh'
if [[ "$(cat "$CASE_DIR/gh.log")" != *'no.txt'* ]]; then PASS=$((PASS + 1)); printf 'ok - extension-excluded\n'; else FAIL=$((FAIL + 1)); printf 'not ok - extension-excluded\n'; fi

case_dir="$TEST_ROOT/case-picker-multi"; mkdir -p "$case_dir"; printf '# one\n' >"$case_dir/one.sh"; printf '# two\n' >"$case_dir/two.sh"; printf 'no\n' >"$case_dir/no.txt"
run_case picker-multi 0 "$SCRIPT" -d test -x sh
assert_contains picker-first "$(cat "$CASE_DIR/gh.log")" 'one.sh'
assert_contains picker-second "$(cat "$CASE_DIR/gh.log")" 'two.sh'
if [[ "$(cat "$CASE_DIR/gh.log")" != *'no.txt'* ]]; then PASS=$((PASS + 1)); printf 'ok - picker-filtered\n'; else FAIL=$((FAIL + 1)); printf 'not ok - picker-filtered\n'; fi

case_dir="$TEST_ROOT/setup-partial"; mkdir -p "$case_dir"; printf 'one\n' >"$case_dir/a.txt"; printf 'two\n' >"$case_dir/b.txt"
run_case partial-failure 1 env GH_FAIL_EDIT_AT=1 "$SCRIPT" -d test "$case_dir/a.txt" "$case_dir/b.txt"
assert_contains partial-url "$CASE_OUTPUT" 'The partial Gist remains at:'

case_dir="$TEST_ROOT/setup-org"; mkdir -p "$case_dir"; printf 'one\n' >"$case_dir/a.txt"
run_case organization-rejected 1 "$SCRIPT" --account org-name -d test "$case_dir/a.txt"
assert_contains org-explanation "$CASE_OUTPUT" 'GitHub Gists cannot be owned by organizations.'

case_dir="$TEST_ROOT/setup-shadow"; mkdir -p "$case_dir"; printf 'one\n' >"$case_dir/a.txt"
run_case stale-env-token-fallback 0 env GITHUB_TOKEN=stale GH_ENV_INVALID=1 "$SCRIPT" -d test "$case_dir/a.txt"
assert_contains stale-token-owner "$CASE_OUTPUT" 'Owner:      @test-user'
assert_contains stale-token-used-stored "$(cat "$CASE_DIR/gh.log")" 'auth token'

printf '\n%d passed; %d failed\n' "$PASS" "$FAIL"
((FAIL == 0))
