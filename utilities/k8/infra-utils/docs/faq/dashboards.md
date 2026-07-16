# FAQ deep-dive: open-dashboard

### Why would I use `open-dashboard` instead of running `kubectl port-forward` myself?

Because remembering the right namespace, service name, and local port for four different
dashboards (Goldilocks, Kubecost, Parca, SigNoz) across clusters is exactly the kind of
detail that's easy to mistype or forget, and `open-dashboard <tool>` bakes in the correct
default for each plus opens your browser automatically. The trade-off is indirection: if a
dashboard's service/namespace has actually changed in the cluster (e.g. after a chart
upgrade renamed it), `open-dashboard`'s baked-in default goes stale before you'd notice
with a manual `port-forward`, which is why `K8_{TOOL}_NS`/`K8_{TOOL}_SVC` overrides exist —
use them the moment the default stops resolving.

→ *See [PROJ-HOWTO.md#how-to-open-a-monitoring-dashboard](../PROJ-HOWTO.md#how-to-open-a-monitoring-dashboard).*

### Is it safe to leave an `open-dashboard` port-forward open, and does it expose anything externally?

`kubectl port-forward` (which `open-dashboard` wraps) only binds to `localhost` on your
machine — it does not expose the dashboard on your LAN or the internet, so leaving it
running is no riskier than leaving any local dev server open. The caveat is entirely
local: the forwarded dashboard (Kubecost cost data, SigNoz traces, Parca profiles) is now
reachable by anything else running as your local user until you `Ctrl-C` it, so treat it
like any other localhost admin UI on a shared or multi-user workstation.
