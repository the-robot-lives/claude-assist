# Waitlist & Email Capture

## Architecture

The waitlist is a client-side form (`waitlist-form.tsx`) that POSTs directly to the foryou public signups API. No server-side proxy or backend is involved. foryou is the portfolio-wide signup service — it handles double opt-in for waitlists, sends the confirmation email, and manages unsubscribe links and an admin/org dashboard at `foryou.therobotlives.com/app`.

## Integration Details

| Field | Value |
|-------|-------|
| Endpoint | `https://foryou.therobotlives.com/api/v1/public/lists/therobotlives-waitlist/signups` |
| Method | POST (JSON) |
| List slug | `therobotlives-waitlist` (must be provisioned in foryou before go-live — see `projects/foryou.therobotlives.com/provisioning/`) |
| Payload | `{ values: { email }, source: "therobotlives-waitlist", company_website: "" }` (`company_website` is an anti-spam honeypot, expected empty) |

## UI States

- **idle** — email input + submit button
- **loading** — button shows "Joining...", input disabled
- **success** — replaced with confirmation message ("You're on the list!")
- **error** — inline error message below input, parsed from the foryou response or generic network error

## Placement

The form appears twice on the landing page:
1. Hero section (primary CTA: "Get Early Access")
2. Final CTA section (secondary: "Join the Waitlist")

## CORS Consideration

The browser makes a cross-origin request to `foryou.therobotlives.com`. foryou's public signups endpoint has CORS configured to allow the site origin (`therobotlives.com`), so the direct client-side POST succeeds without a proxy.
