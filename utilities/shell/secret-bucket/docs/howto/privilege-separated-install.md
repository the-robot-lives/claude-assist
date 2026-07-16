# How to: let an agent touch secrets without being able to read them

**Goal:** run `secret-bucket` as a narrow root helper behind `sudo -n`, so an
unprivileged agent user can diff/copy/set on an allowlisted set of files
while the raw files themselves are `root`-owned and unreadable to that user.
**Prereqs:** root access on the box; `cargo build --release` already run;
an agent/service account (`AGENT_USER`) distinct from `root`.

1. Install the binary root-owned, not agent-writable:
   ```bash
   sudo install -m 755 -o root -g wheel target/release/secret-bucket /usr/local/sbin/secret-bucket
   ```
2. Install the policy allowlist (edit paths before or after copying):
   ```bash
   sudo mkdir -p /etc/secret-bucket
   sudo install -m 644 -o root -g wheel docs/policy.example.yaml /etc/secret-bucket/policy.yaml
   sudo $EDITOR /etc/secret-bucket/policy.yaml
   ```
   Policy shape — list every absolute path the agent may touch, per operation:
   ```yaml
   allow:
     read:
       - /path/to/.envrc
       - /path/to/.envrc.k8.dc
     write:
       - /path/to/.envrc.k8.dc
     value_file:
       - /path/to/secrets/inbox
   ```
3. Lock down the secret files themselves so only root can read them (this is
   what actually protects the values — the policy file alone does not):
   ```bash
   sudo chown root:root /path/to/.envrc.k8.dc
   sudo chmod 600 /path/to/.envrc.k8.dc
   ```
4. Install the sudoers rule — always via `visudo`, using
   [sudoers.example](../sudoers.example) as the template:
   ```bash
   sudo visudo -f /etc/sudoers.d/secret-bucket
   ```
   It scopes `NOPASSWD` sudo to exactly the `secret-bucket` binary for
   `AGENT_USER`, and disables sudo I/O logging for that command (the tool's
   own output is already value-free; I/O logging would just be redundant
   capture surface).
5. The agent now calls it as:
   ```bash
   sudo -n /usr/local/sbin/secret-bucket \
     --policy /etc/secret-bucket/policy.yaml \
     diff envrc:/path/to/.envrc dcfile:/path/to/.envrc.k8.dc:k8
   ```

**Verify:**
- As `AGENT_USER`: `cat /path/to/.envrc.k8.dc` → permission denied.
- As `AGENT_USER`: the `sudo -n secret-bucket --policy ... list ...` command above succeeds and prints only key names.
- As `AGENT_USER`: the same command against a path *not* in the policy fails with `policy denied <Access> access to <path>`.

**Gotchas:**
- **Policy path must be absolute** — a relative `--policy policy.yaml` is
  rejected outright (`policy path must be absolute`), even if it resolves
  correctly from the cwd.
- **Policy file must not be group/world writable** — `chmod 664` on the
  policy file makes every command using it fail with
  `policy file must not be group/world writable`. Keep it `644` and
  root-owned.
- **All paths are canonicalized before matching** — symlinks pointing outside
  the allowlist are rejected, and a policy entry for a directory allows
  everything canonicalized under it, so scope directory entries narrowly.
- **The policy allowlist is not what hides the values** — a `secret-bucket`
  command run *without* `--policy` (or run directly as root/an unrestricted
  user) can still read and print key lists for any file it can access on
  disk. The actual confidentiality boundary is step 3 (root ownership + mode
  600 on the secret files) plus the sudoers restriction in step 4 — the
  policy file only prevents an already-privileged `secret-bucket` invocation
  from touching paths outside the intended scope.
