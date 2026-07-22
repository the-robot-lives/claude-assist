# 07: Service Settings & Branding

| Field | Value |
|-------|-------|
| ID | SCR-07 |
| Type | settings |
| Category | Services & Branding |
| User Stories | US-014, US-016, US-017, US-018, US-022 |

## Description
Configure a Service's identity: name/slug/description, branding (logo/colors),
sender identity (from/reply-to), site domain mapping, and a public-appearance
preview.

## Key Components
- FormField — settings inputs
- BrandingEditor — logo upload + color pickers
- SenderIdentityFields — from-name/from-email/reply-to
- DomainMappingField — allowed origin/domain entry
- PreviewPane — public form preview with branding
- Button — save / cancel

## Interactions
- Edit settings, branding, sender identity, domain mapping
- Live preview of the branded public form; read-only when unauthorized

## Navigation
- **From:** Service Overview (SCR-06); Services List (SCR-05)
- **To:** Org Members & Invites (SCR-04); Lists Management (SCR-08)
