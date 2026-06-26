# foryou.TheRobotLives.com

A hosted **signup, landing-page, and contact-preference service** for the
DeRobot / TheRobotLives portfolio of sites.

`foryou` lets each site define its own signup forms and mailing lists, collect
arbitrary structured data from sign-ups, and give every person a single place to
manage how — and how often — they hear from us, across **all** portfolio sites.

---

## What it does

1. **Capture sign-ups** — Drop a landing page or embeddable form on any site to
   collect beta-access requests, waitlist entries, newsletter subscriptions, or
   any custom list.
2. **Model arbitrary data** — Each list defines its own typed attributes (email,
   name, invite token, "why do you want access?", etc.). No schema migrations to
   add a field.
3. **Manage contact preferences** — Sign-ups can include delivery preferences
   (frequency, channels, quiet periods). People log in later to adjust them.
4. **One identity, every site** — A single account manages contact preferences
   across the whole portfolio: `foryou.therobotlives.com`, `codefre.sh`, and the
   other DeRobot sites.

---

## Core concepts

### Service
The top-level tenant — typically one per site or product (e.g. *TheRobotLives*,
*codefre.sh*). A service owns one or more lists and its own branding.

### List
A named collection that people sign up to within a service (e.g. *Beta Access*,
*Weekly Digest*, *Launch Waitlist*). Each list declares its own set of
attributes and, optionally, contact-preference controls.

### Attribute
A typed, named field on a list. Attributes are arbitrary — a list defines
whatever it needs to collect. Supported types:

| Type           | Notes                                              |
| -------------- | -------------------------------------------------- |
| `string`       | Free text                                          |
| `email`        | Validated email address                            |
| `int`          | Whole number                                       |
| `float`        | Decimal number                                     |
| `date`         | Calendar date                                      |
| `guid`         | Unique identifier (e.g. invite token)              |
| `select`       | Single choice from a fixed set of options          |
| `multi-select` | Zero or more choices from a fixed set of options   |

### Contact preferences
Some lists collect **delivery preferences** alongside their attributes. These
control whether and how a person is contacted:

- **Frequency** — how often (e.g. immediate, daily, weekly, monthly).
- **Periods** — when contact is allowed (e.g. quiet hours, opt-out windows).
- **Channels** — where to reach them:
  - `email`
  - `sms`
  - `mobile` (push)
  - `webhook`
  - `physical mail`

---

## Example: a beta-access list

A *Beta Access* list on a site might define these attributes:

| Attribute      | Type     | Purpose                                  |
| -------------- | -------- | ---------------------------------------- |
| `email`        | `email`  | Where to send the invite                 |
| `name`         | `string` | Who they are                             |
| `invite_token` | `guid`   | Optional referral / invite token, if any |
| `justification`| `string` | Why they'd like access                   |

A newsletter-style list, by contrast, would lean on **contact preferences** —
letting the subscriber pick their channels (email + SMS), a weekly frequency,
and a quiet period.

---

## Unified preference center

People don't manage a separate subscription for every site. After signing up,
they can log in to a single account and edit their contact preferences for:

- the site they signed up on (`foryou.therobotlives.com`), **and**
- every other DeRobot portfolio site (`codefre.sh`, …).

This gives each person one authoritative, cross-site view of what they've
subscribed to and how they want to be reached — and gives every site a
consistent, compliant preference-management surface without reimplementing it.

---

## Status

Early definition stage. This README captures the intended product surface;
implementation details (stack, schema, API) are TBD.

## See also

- Repository conventions and deployment: monorepo root `CLAUDE.md`.
- Sibling portfolio sites under `projects/`.
