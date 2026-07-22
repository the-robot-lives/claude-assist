#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT/bin/claude-sandbox"
TEST_TMP="$(mktemp -d /tmp/claude-sandbox-tests.XXXXXX)"
trap 'rm -rf -- "$TEST_TMP"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_contains() {
  local needle="$1" file="$2"
  grep -Fqx -- "$needle" "$file" || fail "expected '$needle' in $file"
}

mkdir -p "$TEST_TMP/bin" "$TEST_TMP/runtime" "$TEST_TMP/root"
touch "$TEST_TMP/runtime/wayland-7" "$TEST_TMP/runtime/wayland-7.lock"

# Capture bwrap's argv without entering a namespace or launching a GUI.
cat >"$TEST_TMP/bin/bwrap" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >"$CLAUDE_SANDBOX_TEST_ARGS"
EOF
chmod 755 "$TEST_TMP/bin/bwrap"

export PATH="$TEST_TMP/bin:$PATH"
export CLAUDE_DESKTOP_BIN=/usr/bin/true
export CLAUDE_SANDBOX_ROOT="$TEST_TMP/root"
export CLAUDE_SANDBOX_TEST_ARGS="$TEST_TMP/bwrap.args"
export XDG_RUNTIME_DIR="$TEST_TMP/runtime"
export WAYLAND_DISPLAY=wayland-7
export DISPLAY=

"$SCRIPT" alpha --empty --foreground >/dev/null

assert_contains --unshare-user-try "$TEST_TMP/bwrap.args"
assert_contains "$TEST_TMP/root/claude-desktop-alpha/tmp" "$TEST_TMP/bwrap.args"
assert_contains /tmp "$TEST_TMP/bwrap.args"
assert_contains "$TEST_TMP/runtime/wayland-7" "$TEST_TMP/bwrap.args"
assert_contains dbus-run-session "$TEST_TMP/bwrap.args"
assert_contains --user-data-dir="$HOME/.config/Claude" "$TEST_TMP/bwrap.args"
if grep -Fqx -- --unshare-pid "$TEST_TMP/bwrap.args"; then
  fail "PID namespaces break Electron stale-lock and callback routing"
fi
if grep -Fqx -- --die-with-parent "$TEST_TMP/bwrap.args"; then
  fail "detached instances must not die with the launcher"
fi

WRAPPER_HOME="$TEST_TMP/root/claude-desktop-alpha/home/.local/bin"
grep -Fq org.freedesktop.portal.OpenURI.OpenURI "$WRAPPER_HOME/sandboxed-browser" \
  || fail "browser wrapper does not use the host portal"
grep -Fq 'gnome-keyring-daemon --unlock' "$WRAPPER_HOME/claude-sandbox-session" \
  || fail "session wrapper does not initialize the private keyring"

# --empty must not inherit auth/config from the automatic template fallback.
mkdir -p "$TEST_TMP/root/claude-desktop-template/home"
touch "$TEST_TMP/root/claude-desktop-template/home/template-marker"
"$SCRIPT" clean --empty --foreground >/dev/null
[ ! -e "$TEST_TMP/root/claude-desktop-clean/home/template-marker" ] \
  || fail "--empty unexpectedly cloned a template"

if "$SCRIPT" '../escape' --foreground >/dev/null 2>&1; then
  fail "unsafe sandbox name was accepted"
fi

echo "✓ claude-sandbox regression tests passed"
