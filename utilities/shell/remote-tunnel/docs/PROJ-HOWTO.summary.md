# PROJ-HOWTO.summary.md

Task list for `remote-tunnel`. See [PROJ-HOWTO.md](PROJ-HOWTO.md) for full steps.

- **Install the tunnel scripts** — get `revtunnel.sh`, `ngrok-nomachine.sh`, `ngrok-cron.sh` on your `PATH` as symlinks back to this repo, so edits here take effect immediately.
- **Publish my SSH access on a remote host I control** — make a NAT'd/firewalled local machine's SSH (and Eternal Terminal) reachable by connecting outbound to a remote host you already have an account on — no port-forwarding on your router needed.
- **Forward additional or different ports** — expose more than the default SSH/Eternal-Terminal pair, or remap the remote-side ports.
- **Expose a local service publicly on demand via ngrok** — get a throwaway public `host:port` for a local TCP service and hand that address to a remote party by writing it to a file on a host they can read.
- **Let a remote host request the ngrok tunnel on its own schedule** — keep the ngrok tunnel down (saving your metered minutes) until a remote party signals they need it, and avoid starting duplicates.
