# PROJ-FAQ.md

Anticipated why/when/compared-to-what questions for `remote-tunnel`. See
[PROJ-HOWTO.md](PROJ-HOWTO.md) for procedures and [PROJ-ARCH.md](PROJ-ARCH.md)
for design rationale — this doc stays on *why would I*.

## Motivation

### Why would I use a reverse SSH tunnel instead of just forwarding a port on my router?

Because you often can't — the machine is behind CGNAT, a corporate firewall,
or a router you don't administer, and a reverse tunnel only requires outbound
access, which is almost never blocked. `revtunnel.sh` dials out from your
machine to a host you *do* control and asks that host to publish a port back
to you, so there's nothing to configure on the network in between. The
trade-off is you need *some* remote host with SSH access as the meeting
point — this doesn't help if you have no such host.

→ *See [PROJ-HOWTO.md#how-to-publish-my-ssh-access-on-a-remote-host-i-control](PROJ-HOWTO.md#how-to-publish-my-ssh-access-on-a-remote-host-i-control).*

### Why maintain two separate tunnel strategies instead of picking one?

Because they solve different problems: `revtunnel.sh` is for *always-on*
access to a host you control, while the ngrok scripts are for a *throwaway,
publicly reachable* endpoint you don't want running (or metered) except when
someone actually asks for it. Collapsing them into one script would force
every use case through whichever trade-off the other one avoids —
always-on-but-private vs. on-demand-but-public.

→ *See [PROJ-ARCH.md#overview](PROJ-ARCH.md#overview).*

## Fit

### When is `revtunnel.sh` the wrong tool for reaching my machine?

When you have no remote host you control with SSH access to act as the
rendezvous point, or when the exposed service needs to be reachable from the
open internet rather than just from that one remote host (and anyone who can
reach it). If you need a public, internet-facing endpoint instead, use the
ngrok path.

→ *See [PROJ-HOWTO.md#how-to-publish-my-ssh-access-on-a-remote-host-i-control](PROJ-HOWTO.md#how-to-publish-my-ssh-access-on-a-remote-host-i-control).*

### When should I reach for `ngrok-nomachine.sh` instead of `revtunnel.sh`?

When you need a genuinely public address for a local TCP service (e.g.
NoMachine) rather than access scoped to one remote host, and you're fine with
that address being ephemeral and metered. If your access model is "one
trusted remote host, indefinitely," the reverse tunnel is the better fit —
it's free, persistent, and doesn't put the service on the open internet.

→ *See [PROJ-HOWTO.md#how-to-expose-a-local-service-publicly-on-demand-via-ngrok](PROJ-HOWTO.md#how-to-expose-a-local-service-publicly-on-demand-via-ngrok).*

### Is this suitable for exposing production or cluster services?

No — it's deliberately host-level personal-machine plumbing, not deploy
tooling. It doesn't source `share/k8-lib`, isn't wired into
`make install-utilities`, and reads nothing from `.infra-config.yaml`; it's
meant for reaching a workstation, not for the k8s/Helm-managed service
surface documented elsewhere in this repo.

→ *See [PROJ-ARCH.md#fit-in-the-noizu-utilities-ecosystem](PROJ-ARCH.md#fit-in-the-noizu-utilities-ecosystem).*

## Comparison

### How does this differ from the repo's Cloudflare Zero Trust / k8s ingress remote-access setup?

Those front cluster-hosted services behind Cloudflare's access control and
TLS termination; `remote-tunnel` fronts a single personal machine that isn't
in the cluster at all and has no DNS entry of its own. There's no overlap in
scope — this package assumes you have neither a domain nor an ingress for the
box you're trying to reach.

→ *See [PROJ-ARCH.md#fit-in-the-noizu-utilities-ecosystem](PROJ-ARCH.md#fit-in-the-noizu-utilities-ecosystem).*

### How does `ngrok-cron.sh` differ from just running `ngrok-nomachine.sh` directly?

`ngrok-cron.sh` adds a remote-triggered on/off switch and a duplicate guard;
`ngrok-nomachine.sh` alone just starts a tunnel every time you run it, with no
concept of "should one be running right now." Use the cron wrapper when a
remote party needs to request access without you being at the keyboard; call
`ngrok-nomachine.sh` directly when you're starting it yourself in the moment.

→ *See [PROJ-HOWTO.md#how-to-let-a-remote-host-request-the-ngrok-tunnel-on-its-own-schedule](PROJ-HOWTO.md#how-to-let-a-remote-host-request-the-ngrok-tunnel-on-its-own-schedule).*

## Capability

### Can I forward more than the default SSH/Eternal Terminal pair?

Yes, via repeatable `--forward REMOTE:HOST:LOCAL` flags — but the first
`--forward` you pass replaces both defaults rather than adding to them, so
re-include `2222:localhost:22` explicitly if you still want SSH alongside a
custom forward.

→ *See [PROJ-HOWTO.md#how-to-forward-additional-or-different-ports](PROJ-HOWTO.md#how-to-forward-additional-or-different-ports).*

### Can the reverse tunnel survive a reboot or a dropped connection on its own?

Reconnects yes, reboots no. `autossh` (with `ExitOnForwardFailure=yes` and
keepalives) will re-dial automatically if the connection drops, but nothing in
this package restarts the process after the machine itself reboots — you
still need to run it under a supervisor (systemd user unit, tmux, `nohup … &`)
for that.

→ *See [PROJ-HOWTO.md#how-to-publish-my-ssh-access-on-a-remote-host-i-control](PROJ-HOWTO.md#how-to-publish-my-ssh-access-on-a-remote-host-i-control) (step 3).*

### Can two remote parties share one ngrok tunnel, or get two different ones at once?

Not really as designed — `ngrok-nomachine.sh` kills any prior `ngrok tcp
PORT` before starting a new one and only reads the *first* tunnel from the
local ngrok API, so it manages one tunnel per host at a time. Multiple
concurrent public tunnels would need separate ports and separate script
invocations, which isn't wired up.

→ *See [PROJ-ARCH.md#known-constraints](PROJ-ARCH.md#known-constraints).*

## Caveats

### Is `BatchMode=yes` with key-only auth a security downgrade?

No — it's the opposite of a downgrade for this use case: it *forces*
non-interactive key auth so the tunnel can run unattended under a supervisor
without ever pausing on a passphrase prompt, which would otherwise stall
silently. The real requirement it pushes onto you is that the key must be
unencrypted or already loaded in an `ssh-agent`; if you use an
encrypted key with no agent, the tunnel will fail to authenticate rather than
prompt.

→ *See [PROJ-ARCH.md#data--control-flow](PROJ-ARCH.md#data--control-flow).*

### What happens if the remote port I want is already bound?

The tunnel exits immediately rather than silently falling back to another
port — `ExitOnForwardFailure=yes` is intentional so a stuck bind fails loudly.
Free the port (kill the leftover tunnel/process holding it) or pick a
different `--forward` spec; there's no automatic renegotiation.

→ *See [PROJ-HOWTO.md#how-to-publish-my-ssh-access-on-a-remote-host-i-control](PROJ-HOWTO.md#how-to-publish-my-ssh-access-on-a-remote-host-i-control) (gotchas).*

### What happens if the ngrok process behind `ngrok-cron.sh` hangs instead of exiting cleanly?

Retries stay blocked until you kill it — the cron guard only checks whether an
`ngrok tcp PORT` process exists, not whether the tunnel is actually healthy, so
a hung-but-still-running process reads as "already running" forever. There's
no health check or timeout that would auto-recover it; you have to notice and
kill the stuck process yourself before the next cron tick can start a working
tunnel.

→ *See [PROJ-HOWTO.md#how-to-let-a-remote-host-request-the-ngrok-tunnel-on-its-own-schedule](PROJ-HOWTO.md#how-to-let-a-remote-host-request-the-ngrok-tunnel-on-its-own-schedule) (gotchas).*

### Why doesn't `ngrok-cron.sh` delete the flag file after starting a tunnel?

By design — cleanup is left to whoever created the flag, since the script has
no reliable way to know when the remote party is actually done with the
tunnel. Auto-deleting on start would also just re-trigger a new tunnel next
poll if the requester hadn't removed their own trigger yet. The trade-off is
manual: remove `--flag`'s file yourself when you're finished, or the script
will keep reporting "already running" and never re-arm for a future request.

→ *See [PROJ-HOWTO.md#how-to-let-a-remote-host-request-the-ngrok-tunnel-on-its-own-schedule](PROJ-HOWTO.md#how-to-let-a-remote-host-request-the-ngrok-tunnel-on-its-own-schedule) (gotchas).*

### Are remote file paths (`--flag`, `--remote-out`) safe to pass arbitrary strings into?

No — they're interpolated unquoted into the remote shell command, so paths
with spaces (or shell metacharacters) aren't supported and could behave
unexpectedly. Keep these paths simple, single-token, and under your own
control; don't pass anything derived from untrusted input.

→ *See [PROJ-ARCH.md#known-constraints](PROJ-ARCH.md#known-constraints).*

## Trust

### Does this repo store my SSH key or ngrok authtoken anywhere?

No — no secrets are stored in this package. SSH keys and the ngrok authtoken
are host-level prerequisites you configure directly with `ssh-keygen`/your
agent and `ngrok config add-authtoken`, and the scripts only reference their
default paths (`~/.ssh/id_ed25519`, ngrok's own config) — nothing is
persisted or transmitted by the scripts themselves beyond the tunnel traffic
and the ephemeral address handoff.

→ *See [PROJ-ARCH.md#known-constraints](PROJ-ARCH.md#known-constraints) and [PROJ-LAYOUT.md](PROJ-LAYOUT.md).*

### Does anything here log or persist the traffic passing through a tunnel?

Not on this repo's side. The scripts only log their own startup/status
(e.g. `ngrok-nomachine.sh` writes ngrok's own log to `/tmp/ngrok.log` for
troubleshooting); the forwarded SSH/Eternal-Terminal/ngrok TCP traffic itself
passes through unmodified and isn't captured or written anywhere by this
package.

→ *See [PROJ-HOWTO.md#how-to-expose-a-local-service-publicly-on-demand-via-ngrok](PROJ-HOWTO.md#how-to-expose-a-local-service-publicly-on-demand-via-ngrok) (gotchas).*
