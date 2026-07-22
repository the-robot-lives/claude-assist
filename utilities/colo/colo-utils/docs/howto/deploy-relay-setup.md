# How to: wire up the deploy relay on the colo server

**Goal:** have the colo server poll GitHub Deployments every 60s and run `helm-upgrade` automatically for anything targeting it — no inbound webhook or push access needed.
**Prereqs:** `gh` CLI authenticated with a PAT that can read/write deployments on the target repo; `helm` + `kubectl` configured on the colo server; `helm-upgrade` (from k8-lib devops tools) on `PATH`; systemd on the target host.

## 1. Copy the units and binary to the colo server

```bash
colo-sync --to /Users/keith/Work/Space/Infra/Noizu/utilities/colo/colo-utils
# then, on the colo server:
sudo install -m 755 colo-utils/bin/colo-deploy-relay /usr/local/bin/colo-deploy-relay
sudo cp colo-utils/colo-deploy-relay.service /etc/systemd/system/
sudo cp colo-utils/colo-deploy-relay.timer /etc/systemd/system/
```

## 2. Adjust the environment for your repo/target

Edit `/etc/systemd/system/colo-deploy-relay.service` and set:
```ini
Environment=DEPLOY_REPO=<org>/<repo>
Environment=DEPLOY_ENV=production
Environment=STATE_DIR=/var/lib/deploy-relay
Environment=REGISTRY=<your-registry>
```
Ensure `User=deploy` (or whichever user runs it) exists and can reach `kubectl`/`helm`/`gh`.

## 3. Enable and start the timer

```bash
sudo systemctl daemon-reload
sudo mkdir -p /var/lib/deploy-relay
sudo chown deploy:deploy /var/lib/deploy-relay
sudo systemctl enable --now colo-deploy-relay.timer
```

## 4. Dry-run one cycle before trusting it

```bash
sudo -u deploy DRY_RUN=true /usr/local/bin/colo-deploy-relay
```

**Verify:**
- `systemctl list-timers colo-deploy-relay.timer` shows the next scheduled run
- `/var/lib/deploy-relay/deploy.log` gets a new "Relay cycle complete" line every 60s
- A test GitHub Deployment against `DEPLOY_ENV` gets an `in_progress` then `success`/`failure` status posted back

**Gotchas:**
- `last-deployment-id` in `STATE_DIR` is the only checkpoint — deleting it replays every deployment ever created for that environment; back it up before touching `STATE_DIR`.
- Deployment payloads must include `project`, `tag`, and (optionally) a `services` map of `{svc: image_path}` — deployments missing `project`/`tag` are skipped and marked processed, not retried.
- The systemd unit hardening (`ProtectSystem=strict`, `ReadWritePaths=/var/lib/deploy-relay`) means the relay can only write there — if `helm-upgrade` or a plugin needs to write elsewhere, add it to `ReadWritePaths` rather than loosening `ProtectSystem`.
- `DRY_RUN=true` still calls `gh api` to fetch/mark deployments (read side is live); only the `helm-upgrade` execution is skipped.
