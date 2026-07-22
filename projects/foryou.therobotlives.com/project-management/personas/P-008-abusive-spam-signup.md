---
id: P-008
name: "Botnet / Spam Signup"
slug: abusive-spam-signup
archetype: "Adversarial actor abusing public signup endpoints"
segment: edge-case
tags: [abuse, spam, security, rate-limit, anti-adversary]
---

# P-008: Botnet / Spam Signup (Adversarial)

## Demographics

| Attribute | Value |
|-----------|-------|
| Age | n/a |
| Occupation | Automated abuse / list-bombing script |
| Location | Distributed / spoofed |
| Tech comfort | expert (automated) |

## Bio
Not a real customer — an adversarial pattern the product must defend against.
Public, CORS-open signup endpoints invite spam signups, email-bombing third
parties, list enumeration, and injection of junk data. The system must stay
usable for real people while resisting this actor.

## Goals (adversarial — to be defeated)
- Mass-submit signups to bomb someone else's inbox with confirmation mail.
- Enumerate which emails exist on a list via response differences.
- Inject malformed or oversized attribute payloads.

## Frustrations (i.e., defenses that stop it)
- Rate limiting and throttling on public endpoints.
- Generic 202 responses that never leak whether an email already exists.
- Double opt-in that neutralizes list-bombing, plus honeypots/CAPTCHA.

## Behaviors
- High-volume, automated, from rotating origins.
- Probes for existence leaks, missing validation, and unbounded fields.
- Targets the widest-open surface: the unauthenticated public signup POST.

## Job to Be Done (inverted — the product's job)
> "When abusive traffic hits the public signup endpoint, the system must protect
> real users and third parties, so signups stay trustworthy and low-noise."

## Relationship to Product
The threat model for the public signup endpoint, widget, and double opt-in flow.
Drives rate-limiting, no-existence-leak responses, input validation, honeypots,
and abuse-monitoring stories.

## Scenarios
- **Scenario 1:** Flood — rapid repeat POSTs are throttled and shed.
- **Scenario 2:** Enumeration — identical generic responses regardless of prior
  membership defeat existence probing.
- **Scenario 3:** Bombing — double opt-in prevents unconfirmed third-party
  inboxes from being subscribed.
