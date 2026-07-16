# How to: log an agent's outbound API traffic

**Goal:** let the agent reach one specific endpoint (e.g. an LLM API) while
every request/response is dumped to disk for review, instead of running with
`internet_access: true` (fully open) or `false` (fully closed).
**Prereqs:** Docker daemon with compose support.

1. Define an outbound service with a mitmproxy sidecar in
   `.agent-sandbox/config`:
   ```yaml
   compose:
     network: agent-sandbox     # shared external network (default name)
     services:
       - name: llm-api
         mitmproxy:
           enabled: true
           mode: log
           upstream: https://api.anthropic.com
           listen_port: 8080
   ```
   Setting `compose.services` (or `base_file`/`network`) switches launch from
   plain `docker run` to docker-compose automatically.
2. Point the agent's client at the sidecar instead of the real upstream, by
   service name:
   ```yaml
   env:
     ANTHROPIC_BASE_URL: "http://llm-api-mitm:8080"
   ```
3. Launch as usual (`agent-sandbox`). The tool creates the shared `agent-sandbox`
   network if missing, brings up `compose.base_file` if set, and generates
   `{worktree}/.agent-sandbox/compose.overlay.yaml` with the agent service plus
   the `llm-api` service and its `llm-api-mitm` sidecar.

**Verify:** after making a request from inside the container, check
`{worktree}/.agent-sandbox/compose.overlay.yaml` for the generated services,
and `{worktree}/.agent-sandbox/mitm/llm-api/` for dumped flow files.

**Gotchas:**
- Both `upstream` and `listen_port` are required for the sidecar to be
  generated — if either is missing, the tool logs a warning and **skips the
  sidecar silently** rather than failing the launch; check launch output for
  `mitmproxy enabled but no listen_port/upstream`.
- `mode: log` is the only wired mode today — `mode: intercept` (MITM-and-modify)
  is designed in the schema but not yet implemented; setting it has no effect.
- `log_dir` defaults to `{worktree}/.agent-sandbox/mitm/<service-name>/` if
  unset — override it in `mitmproxy.log_dir` to centralize logs elsewhere.
- In compose mode the shared network is a normal bridge, not an isolated one —
  this gives you *logging*, not *egress control*; true internal-network
  isolation for compose mode is a later milestone (see PROJ-ARCH.md).
