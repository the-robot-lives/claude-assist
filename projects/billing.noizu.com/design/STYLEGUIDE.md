# Billing Noizu Style Guide

## Style Name

**Bureau Signal**: a financial-operations interface that feels like a secure back-office ledger crossed with a command surface. It should not look like a generic blue SaaS dashboard or a beige accounting template.

## Positioning

Billing Noizu is precise, operational, and agent-aware. The interface should communicate that money movement is controlled, auditable, and human-approved, while still feeling faster than a traditional accounting suite.

## Visual Principles

1. **Ledger-first structure** - rows, totals, and state changes align to strong vertical and horizontal rules.
2. **Signal color, not decoration** - color identifies action state: teal for proceed, amber for attention, red for risk, blue for information.
3. **Instrument density** - dashboards are compact enough for repeated finance work without becoming visually noisy.
4. **Human approval emphasis** - external financial actions use deliberate, high-contrast controls and clear confirmation states.
5. **Quiet uniqueness** - distinctive through layout rhythm, rail treatment, and status language rather than novelty interactions.

## Palette

| Token | Hex | Use |
|-------|-----|-----|
| Ink | `#161a1d` | Primary text |
| Graphite | `#283136` | Sidebar, high-emphasis panels |
| Fog | `#eef2ef` | Page background |
| Paper | `#fbfaf6` | Main surfaces |
| Rule | `#cfd8d3` | Borders and ledger lines |
| Teal Signal | `#007c72` | Primary actions and connected state |
| Blue Ledger | `#274c77` | Information state and links |
| Amber Hold | `#b86b00` | Pending or needs-review state |
| Red Exception | `#b42318` | Failed, overdue, destructive |
| Lilac Agent | `#6f5cc2` | Agent-assist disclosure and generated suggestions |

## Typography

- Family: system sans (`Inter`, `SF Pro`, `Segoe UI`, fallback sans).
- Numeric data uses tabular numerals.
- Headings stay compact; no oversized hero treatment inside the app.
- Labels use uppercase only for short operational eyebrows.

## Shape And Layout

- Radius: `6px` for operational panels and controls, `3px` for badges.
- Sidebar is dark graphite to differentiate the product from pale accounting templates.
- Cards use a left signal rail for state instead of large decorative color blocks.
- Tables/lists keep stable row heights and predictable columns.

## Component Rules

- Primary button: teal fill, white text, minimum 44px height.
- Secondary button: paper fill, graphite border.
- Empty states: show system readiness and next integration step, not fake sample data.
- Agent-assisted content: lilac badge plus explicit review-required copy.
- Risk state: red text/icon only when money, delivery, or customer trust is affected.

## Accessibility

- Body text must meet WCAG 2.2 AA contrast.
- Focus states use a visible 2px blue ledger outline.
- Do not rely on color alone for invoice/payment status.
- Reduced-motion users receive no animated numeric transitions.
