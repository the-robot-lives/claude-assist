# PROJ-FAQ.summary.md

Question index only — see [PROJ-FAQ.md](PROJ-FAQ.md) for answers.

## Motivation
- Why would I use a reverse SSH tunnel instead of just forwarding a port on my router?
- Why maintain two separate tunnel strategies instead of picking one?

## Fit
- When is `revtunnel.sh` the wrong tool for reaching my machine?
- When should I reach for `ngrok-nomachine.sh` instead of `revtunnel.sh`?
- Is this suitable for exposing production or cluster services?

## Comparison
- How does this differ from the repo's Cloudflare Zero Trust / k8s ingress remote-access setup?
- How does `ngrok-cron.sh` differ from just running `ngrok-nomachine.sh` directly?

## Capability
- Can I forward more than the default SSH/Eternal Terminal pair?
- Can the reverse tunnel survive a reboot or a dropped connection on its own?
- Can two remote parties share one ngrok tunnel, or get two different ones at once?

## Caveats
- Is `BatchMode=yes` with key-only auth a security downgrade?
- What happens if the remote port I want is already bound?
- What happens if the ngrok process behind `ngrok-cron.sh` hangs instead of exiting cleanly?
- Why doesn't `ngrok-cron.sh` delete the flag file after starting a tunnel?
- Are remote file paths (`--flag`, `--remote-out`) safe to pass arbitrary strings into?

## Trust
- Does this repo store my SSH key or ngrok authtoken anywhere?
- Does anything here log or persist the traffic passing through a tunnel?
