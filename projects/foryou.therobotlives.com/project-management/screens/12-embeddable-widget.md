# 12: Embeddable Widget

| Field | Value |
|-------|-------|
| ID | SCR-12 |
| Type | primary |
| Category | Signups & Subscriptions |
| User Stories | US-046, US-047, US-048, US-096 |

## Description
The drop-in signup widget (script/iframe) embedded on external portfolio sites.
Renders a List's attributes dynamically, themes to the host, and submits
cross-origin to the CORS-enabled public endpoint.

## Key Components
- WidgetContainer — script/iframe host with isolation
- DynamicForm — attribute-driven renderer (shared with SCR-11)
- FormField — per-type field renderers
- ThemeAdapter — applies theme options / Service branding
- InlineAlert — cross-origin/validation errors

## Interactions
- Embed via one snippet; dynamic fields; theming
- Cross-origin submit with CORS preflight; graceful error on disallowed origin

## Navigation
- **From:** any external portfolio site
- **To:** Opt-in Confirmation (SCR-13)
