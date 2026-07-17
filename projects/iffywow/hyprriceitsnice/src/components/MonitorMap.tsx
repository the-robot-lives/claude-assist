import { AI_LAYOUT, MONITORS, WS_TITLES } from "@/lib/bindings";

export function MonitorMap() {
  return (
    <section className="grid gap-4 lg:grid-cols-2">
      <div className="rounded-xl border border-tn-border bg-card/70 p-4">
        <h2 className="mb-3 text-sm font-semibold tracking-wide text-tn-cyan">
          Dual stack
        </h2>
        <div className="flex flex-col items-center gap-2">
          {/* External */}
          <div className="w-full max-w-md rounded-lg border-2 border-tn-blue/70 bg-gradient-to-br from-tn-blue/15 to-tn-magenta/10 p-3 shadow-[0_0_24px_rgba(122,162,247,0.12)]">
            <div className="flex items-start justify-between gap-2">
              <div>
                <div className="text-xs font-semibold text-tn-blue">{MONITORS[0].label}</div>
                <div className="font-mono text-[10px] text-muted">{MONITORS[0].name}</div>
              </div>
              <div className="rounded-full bg-tn-blue/20 px-2 py-0.5 text-[10px] text-tn-blue">
                WS {MONITORS[0].workspaces}
              </div>
            </div>
            <div className="mt-2 text-[11px] text-foreground/80">
              {MONITORS[0].mode} · scale {MONITORS[0].scale}
            </div>
            <div className="mt-1 text-[10px] text-muted">{MONITORS[0].role}</div>
            <div className="mt-3 flex flex-wrap gap-1">
              {[1, 2, 3, 4, 5].map((n) => (
                <span
                  key={n}
                  className="rounded-md border border-tn-border bg-tn-bg-dark px-2 py-1 text-[10px]"
                >
                  <span className="text-tn-blue">{n}</span>
                  {WS_TITLES[String(n)] && (
                    <span className="ml-1 text-muted">{WS_TITLES[String(n)]}</span>
                  )}
                </span>
              ))}
            </div>
          </div>

          {/* Connector line */}
          <div className="h-4 w-px bg-tn-border" />

          {/* Laptop */}
          <div className="w-[75%] max-w-sm rounded-lg border border-tn-magenta/60 bg-gradient-to-br from-tn-magenta/10 to-transparent p-3">
            <div className="flex items-start justify-between gap-2">
              <div>
                <div className="text-xs font-semibold text-tn-magenta">{MONITORS[1].label}</div>
                <div className="font-mono text-[10px] text-muted">{MONITORS[1].name}</div>
              </div>
              <div className="rounded-full bg-tn-magenta/20 px-2 py-0.5 text-[10px] text-tn-magenta">
                WS {MONITORS[1].workspaces}
              </div>
            </div>
            <div className="mt-2 text-[11px] text-foreground/80">
              {MONITORS[1].mode}
            </div>
            <div className="mt-0.5 text-[10px] text-muted">{MONITORS[1].scale}</div>
            <div className="mt-3 flex flex-wrap gap-1">
              {[6, 7, 8, 9].map((n) => (
                <span
                  key={n}
                  className="rounded-md border border-tn-border bg-tn-bg-dark px-2 py-1 text-[10px]"
                >
                  <span className="text-tn-magenta">{n}</span>
                </span>
              ))}
            </div>
          </div>
        </div>
      </div>

      <div className="rounded-xl border border-tn-border bg-card/70 p-4">
        <h2 className="mb-3 text-sm font-semibold tracking-wide text-tn-green">
          AI workspace layout
        </h2>
        <p className="mb-3 text-[11px] text-muted">
          special:ai · floats use % of focused monitor · SUPER+A toggle · SUPER+SHIFT+A launch
        </p>
        <div className="relative aspect-[16/9] w-full overflow-hidden rounded-lg border border-tn-border bg-tn-bg-dark">
          {/* Chrome */}
          <div className="absolute left-[1%] top-[1%] h-[72%] w-[58%] rounded-md border border-tn-blue/50 bg-tn-blue/15 p-2">
            <div className="text-[10px] font-medium text-tn-blue">Chrome</div>
            <div className="text-[9px] text-muted">58% × 72%</div>
          </div>
          {/* Obsidian */}
          <div className="absolute left-[59%] top-[1%] h-[97%] w-[40%] rounded-md border border-tn-magenta/50 bg-tn-magenta/15 p-2">
            <div className="text-[10px] font-medium text-tn-magenta">Obsidian</div>
            <div className="text-[9px] text-muted">40% × 97%</div>
          </div>
          {/* Term */}
          <div className="absolute bottom-[2%] left-[1%] h-[22%] w-[58%] rounded-md border border-tn-green/50 bg-tn-green/10 p-2">
            <div className="text-[10px] font-medium text-tn-green">Terminal</div>
            <div className="text-[9px] text-muted">58% × 22%</div>
          </div>
        </div>
        <ul className="mt-3 space-y-1">
          {AI_LAYOUT.map((row) => (
            <li
              key={row.app}
              className="flex justify-between gap-2 text-[11px] text-foreground/85"
            >
              <span>{row.app}</span>
              <span className="font-mono text-muted">{row.place}</span>
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}
