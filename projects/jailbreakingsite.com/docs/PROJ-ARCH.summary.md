# Project Architecture — Summary

**System**: Statically-exported Next.js 16 landing page for an LLM security platform (pre-launch waitlist).

**Stack**: Next.js 16, React 19, TypeScript 5, Tailwind CSS v4, nginx, Docker.

**Components**: Single-page landing (`page.tsx`), client-side waitlist form (foryou signup service), nginx static server, SecOps Terminal design system.

**Build**: `next build` (static export) → Docker multi-stage (node:22-alpine builder → nginx:alpine) → push to `ops.noizu.com/app-jailbreakingsite`.

**Design**: Dark-first "SecOps Terminal" aesthetic — JetBrains Mono, severity-mapped colors, data-dense layout for security professionals.

**Integrations**: foryou signup service (double opt-in email subscriptions), Cloudflare (DNS/TLS/CDN), ops.noizu.com Docker registry.

**Key decisions**: Static export (no server needed), nginx over Node runtime (smaller/faster), self-hosted foryou signup service (portfolio-wide, data ownership), no backend yet (pre-launch).

**Future**: Catalog (attack database), Defender (LLM security scanner), Academy (CTF labs) — will require full-stack migration.
