# 20: BrandingEditor

| Field | Value |
|-------|-------|
| ID | CMP-20 |
| Category | Input & Forms |
| Used In | SCR-07 |

## Description
The Service branding editor: logo upload, color selection, and sender-identity
fields, with a live PreviewPane of the resulting public form.

## Size Variants

| Variant | Use Case |
|---------|---------|
| Full | Complete branding + sender identity editing |
| Compact | Logo + primary color only |

## Props / Configuration
- `logo` — upload + validation
- `colors` — palette pickers
- `sender` — from-name/from-email/reply-to
- `onChange` — updates preview
- `previewRef` — bound PreviewPane

## Interactions
- Upload/validate logo; pick colors; set sender identity
- Live preview updates; falls back to defaults when incomplete
