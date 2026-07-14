---
skill: trl-marketing
version: "1.0"
compatible_with:
  - claude-code
  - claude-teams
  - codex
  - grok
last_updated: 2026-07-15
---

# Marketing — Introduction

Product marketing and launch execution for solo developers and small teams shipping portfolio products and tools-as-products. Takes a built (or nearly built) product and produces positioning, messaging, launch plans, announcement sets, social campaigns, press/outreach materials, and launch retros. Its value is turning "it's done, now what?" into a sequenced launch with measurable outcomes. It does not do SEO, audience-building content, market validation, page design, or pricing — see handoffs below.

## Input Contract

```yaml
inputs:
  arguments:
    - name: task
      type: freeform
      required: true
      description: "What to do: position, plan a launch, write announcements, run a campaign, or retro"
      example: "plan a Product Hunt launch for gotta.cc"
    - name: product
      type: freeform
      required: false
      description: "Product name/URL and one-line description if not in repo context"
      example: "shipctl — one-command deploy CLI"

  file_conventions:
    - pattern: "marketing/{product}/messaging-worksheet.md"
      format: markdown
      description: "Completed positioning intake (copy of assets/messaging-worksheet.md); created if absent"
      schema: "assets/messaging-worksheet.md"
      example: |
        ## Product
        Name: shipctl
        One-liner: One-command deploys without CI YAML
    - pattern: "marketing/{product}/launch-checklist.md"
      format: markdown
      description: "Active launch checklist with dates filled in (copy of assets/launch-checklist.md)"
      schema: "assets/launch-checklist.md"

  context_expectations:
    - "A working or demoable product (marketing amplifies; it does not validate)"
    - "README or landing page draft describing the product, if one exists"
    - "Optional: prior launch retros in marketing/{product}/"
```

## Output Contract

```yaml
outputs:
  artifacts:
    - name: "Positioning brief"
      path: "marketing/{product}/positioning.md"
      format: markdown
      description: "Positioning statement, message hierarchy, landing-page copy block"
      example: |
        # shipctl — Positioning
        ## Statement
        For solo devs who deploy side projects, shipctl is a deploy CLI
        that ships in one command — unlike CI pipelines, it needs no YAML.
    - name: "Launch plan"
      path: "marketing/{product}/launch-plan.md"
      format: markdown
      description: "Launch type, timeline (T-30→T+7), channel assignments, asset list"
    - name: "Announcement set"
      path: "marketing/{product}/announcements/"
      format: directory-tree
      description: "Release post, launch thread, per-platform posts, PH tagline/first comment, demo script"
    - name: "Launch retro"
      path: "marketing/{product}/retro-{date}.md"
      format: markdown
      description: "Funnel numbers, channel attribution, keep/change/try decisions"

  side_effects:
    - "None — all output is file-based; posting to platforms is done by the operator"

  handoff:
    - skill: trl-seo-guru
      artifact: "Announcement set + landing copy"
      description: "Optimize published launch content for search and AI answer engines"
    - skill: trl-content-publishing
      artifact: "Launch retro + audience learnings"
      description: "Convert launch attention into newsletter/audience via ongoing content"
    - skill: trl-user-experience-engineer
      artifact: "Landing-page copy block in positioning.md"
      description: "Design and implement the landing page around the copy"
```

## Conventions

```yaml
conventions:
  naming:
    - "All output files kebab-case under marketing/{product}/"
    - "Announcement files named {channel}-{date}.md (e.g. x-thread-2026-07-20.md)"
  structure:
    - "One product per invocation; one launch plan per launch beat"
    - "Every outbound link in copy carries UTM parameters (source/medium/campaign)"
  anti_patterns:
    - "Do not write copy before the messaging worksheet is complete — positioning before promotion"
    - "Do not reuse identical copy across platforms — each channel gets platform-native content"
    - "Do not plan SEO keywords, newsletter funnels, or pricing here — hand off instead"
  prerequisites:
    - "Product must be demoable; if the niche is unvalidated, route to trl-market-intelligence first"
```

## Reading Order

| Priority | File | When to Read |
|----------|------|-------------|
| 1 (always) | `INTRODUCTION.md` | Before any interaction (you're reading it now) |
| 2 (before executing) | `SKILL.md` | Launch-type/channel selection tables and workflow |
| 3 (during execution) | `references/agent-playbook.claude-code.md` | When running a specific workflow |
| 4 (as needed) | `references/positioning-and-messaging.md` | Positioning or landing-copy tasks |
| 4 (as needed) | `references/launch-playbook.md` | Launch planning tasks |
| 4 (as needed) | `references/announcement-writing.md` | Announcement/changelog/demo-script tasks |
| 4 (as needed) | `references/social-campaign-patterns.md` | Social campaign tasks |
| 4 (as needed) | `references/press-and-outreach.md` | Press kit / outreach tasks |
| 4 (as needed) | `references/launch-metrics.md` | Funnel setup and retro tasks |

## Quick Examples

### Full launch
`/trl-marketing plan and prep a Show HN launch for codefre.sh`

### Single announcement
`/trl-marketing write the v2.0 release announcement set for derobot.is`

### Handoff downstream
After announcements ship, invoke `/trl-seo-guru optimize marketing/codefresh/announcements/ for AI answer engines`
