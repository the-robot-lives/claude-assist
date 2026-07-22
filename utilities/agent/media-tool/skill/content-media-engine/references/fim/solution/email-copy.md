# Email Copy — subject lines, preheaders & campaign bodies

Persuasion built for the inbox: a subject line and preheader that earn the *open*, then a concise body
that earns the *click* — all rendered across dozens of email clients with wildly different truncation
points and image-blocking defaults. Email is permission-based and legally regulated (CAN-SPAM, GDPR),
so it must include an unsubscribe path and honest framing. Good email copy front-loads the value in
the first 40 characters, drives to a single CTA, and reads like a message from a person; bad email
copy uses clickbait subjects, competes with five CTAs, and buries the point below the fold.

**Output form**: plain text or lightly-structured (subject / preheader / body / CTA)
**Typical length**: subject ≤40–50 chars; body 50–200 words (promo) — shorter converts
**Routed via**: `text_format: email-copy` (chat-type generation)

## Genre Conventions & Structure

- **Subject line**: the single highest-leverage element — it alone decides the open. One clear idea,
  front-loaded, curiosity or value, no clickbait.
- **Preheader (preview text)**: the snippet shown next to/under the subject in the inbox. Acts as a
  *second headline* — extends the subject, never repeats it. If unset, clients pull the first body
  line (often "View in browser" — a wasted first impression), so always author it.
- **Preview pairing**: subject + preheader read together as a two-line hook. Short subject → preheader
  adds context; long subject → preheader reinforces the opening words.
- **Body**: one message, one goal. Opening line hooks (visible in the preview), 1–3 short paragraphs of
  value, then the CTA. Scannable — most read on mobile in seconds.
- **Single primary CTA**: one button/link, repeated at most twice (top-ish and bottom). Competing CTAs
  fracture the click.
- **Signature / sender**: a real person's name lifts trust over "The Team."
- **Footer**: physical mailing address + one-click unsubscribe (legally required for promotional mail).

**Transactional vs promotional** — different rules:
- *Transactional* (receipts, password resets, order confirmations): triggered, expected, exempt from
  some CAN-SPAM promotional rules; must be accurate and not primarily promotional.
- *Promotional* (newsletters, offers, nurture): must carry unsubscribe + address, honest subject, and
  respect consent.

## Hard Constraints

Web-verified 2026 display data — checkable:
- **Subject line**: optimal **~30–50 chars** (data suggests 36–50 for open rate). Mobile truncation is
  the real limit — **Gmail app shows ~30 chars**, iPhone portrait ~41, so **front-load the key message
  in the first ~33–40 chars** for universal visibility.
- **Preheader**: **40–100 chars** optimal; ~40–90 visible on Gmail mobile, ~2 lines on Apple Mail.
  Under-30 also performs well. Don't exceed ~100 or the tail is invisible.
- **CTA button label**: 2–5 words, verb-first.
- **CAN-SPAM (US) requirements** (all mandatory for promotional email):
  1. Accurate "From"/"Reply-to" and routing info.
  2. Non-deceptive subject line (must match the body).
  3. Identification as an ad where applicable.
  4. A valid **physical postal address**.
  5. A clear, working **opt-out/unsubscribe** honored within 10 business days.
- **GDPR/consent** (EU): affirmative opt-in and easy withdrawal for marketing mail.
- **Character count includes spaces**; emoji in subjects render inconsistently and can trip spam filters.

## How-To (worked recipes)

### How to write a subject line that survives mobile truncation
Put the payoff in the first 3–4 words; assume everything after char ~33 is cut on Gmail mobile.
- Draft (58, cut mid-word on mobile): "We've Just Released Our Biggest Product Update of the Year" ✗
- Fit (34): "Your biggest update yet is live" ✓ — value in the first three words, whole line visible.

### How to use the preheader as a second headline
Never let it repeat the subject or default to boilerplate. Extend the hook.
- Subject: "Your biggest update yet is live"
- Preheader: "3 features you asked for — and one you didn't see coming." ← adds specifics, pulls the open.

### How to drive to a single CTA
Decide the *one* action, cut everything that competes. A promo with "Shop the sale," "Read the blog,"
and "Follow us" converts worse than one "Shop the sale — 30% off ends Sunday" repeated twice.
- Body ends: **[ Shop the Sale → ]** and a text link mirroring it above the fold.

### How to segment tone to the audience
The same offer needs different framing per segment. A new subscriber gets a welcome/education tone; a
lapsed customer gets a win-back with a reason to return; a power user gets an insider/early-access tone.
Read the segment in the brief and set register accordingly rather than blasting one generic voice.

### How to stay CAN-SPAM compliant without killing the copy
Honest subject that matches the body, one-click unsubscribe in the footer, real postal address, and no
deceptive "Re:"/"Fwd:" fakery. Compliance is a copy constraint, not an afterthought — bake the
unsubscribe and address into the template every time.

## Worked Example — subject/preheader A/B set + full email

Real-form promotional email for the same invoicing tool. Five subject variants for testing, a distinct
preheader, a tight one-CTA body, and a compliant footer.

```
SUBJECT VARIANTS (≤~40 chars, value front-loaded):
 A  Get paid 9 days faster           (24)  — benefit-led
 B  Stop chasing unpaid invoices     (28)  — pain-led
 C  Your invoices, now on autopilot  (31)  — mechanism
 D  34 days is too long to get paid  (31)  — stat hook (real figure only)
 E  One click and the chasing stops  (31)  — outcome/curiosity

PREHEADER (extends the subject, ~55 chars):
  AcmeInvoice follows up for you — politely, automatically.

BODY:
  Hi Sam,

  You did the work weeks ago. The invoice is still sitting unpaid, and now
  you're drafting another "just checking in" email.

  AcmeInvoice sends it for you. It tracks when a client opens the invoice and
  sends polite, on-brand reminders on a schedule you set — until they pay.
  Most freelancers get paid about 9 days sooner and never send a follow-up again.

  Set it up in an afternoon. Your first 14 days are free, no card required.

  [ Start free → ]

  — Dana, founder of AcmeInvoice

FOOTER (required):
  AcmeInvoice, 500 Market St, San Francisco, CA 94105
  You're receiving this because you signed up at acme.example.
  [Unsubscribe] — one click, honored immediately.
```

Why it works: every subject fits mobile truncation with value in the first 3 words; preheader adds
info instead of repeating; one hook line (shows in preview) → value → single CTA; real sender name;
address + one-click unsubscribe present; honest subject matches body; no fabricated urgency.

## Do's and Don'ts

### ✅ Do
- Front-load the subject; make the first 3–4 words carry the value.
- Write the preheader as a distinct second hook that extends the subject.
- Keep the body tight and scannable; one message, one goal.
- Use one primary CTA, verb-first, repeated at most twice.
- Include a working unsubscribe and physical address on every promotional send.

### ❌ Don't
- Use clickbait or deceptive subjects ("Re: your order" when there's no order) — illegal and trust-killing.
- Repeat the subject verbatim in the preheader — wastes a second headline.
- Stuff multiple competing CTAs — split focus lowers clicks.
- Bury the offer or CTA below a long intro — most readers never scroll.
- Over-use emoji/ALL CAPS/`!!!` in the subject — spam-filter and credibility risk.

## Tone, Voice & Register

Conversational, personal, second person — an email is a message *to someone*, not a broadcast. Warmer
and more direct than ad copy; a real sender name and a human opening line beat corporate voice. Register
tracks segment and email type: transactional = clear and neutral; welcome = warm; promo = energetic-but-
honest; win-back = empathetic. Brevity is respect — say it and get out. Active voice, short sentences,
one idea per paragraph.

## Platform / Placement Constraints

- **Client fragmentation**: Gmail, Apple Mail, Outlook each truncate subjects/preheaders differently and
  handle HTML/CSS inconsistently — the subject/preheader budgets above are the safe floor.
- **Image blocking**: many clients block images by default — never put the core message or CTA *only* in
  an image; the copy must work as text alone. Provide alt text.
- **Plain-text vs HTML**: send/author a plain-text alternative; some readers and filters prefer it, and
  it improves deliverability. Don't rely on styling to carry meaning.
- **Mobile-first**: majority of opens are mobile — single column, thumb-reachable CTA, big-enough tap target.
- **Deliverability**: spam-trigger words ("FREE!!!", "act now", excessive punctuation), all-image emails,
  and misleading subjects hurt inbox placement regardless of copy quality.

## Common Pitfalls & Anti-patterns

- **AI-tell openers**: "In today's fast-paced world," "We hope this email finds you well," "I wanted to
  reach out," "In this newsletter, we're excited to share" — delete; open with the value or a human line.
- **Clickbait / deceptive subjects**: fake "Re:"/"Fwd:", "You've won," false urgency — CAN-SPAM violation
  and a fast unsubscribe.
- **Hollow CTAs**: "Learn more," "Click here" with no value context; or five CTAs competing for the click.
- **Preheader waste**: leaving it to default to "View in browser | Unsubscribe" or repeating the subject.
- **Subject over-length / back-loaded value**: the point sitting after char 40 where mobile cuts it.
- **Fabricated urgency/stats**: "Only 3 left!" or "Join 50,000 subscribers" when untrue — trust and legal risk.
- **Emoji/CAPS/`!!!` spam**: hurts deliverability and reads as a blast, not a message.
- **Em-dash overuse and uniform AI rhythm**: reads as machine-written, lowers the personal feel email needs.
- **Wall-of-text body**: long paragraphs no one reads on a phone.

## Prep-Agent Notes (media-tool specific)

From a raw brief:
1. Identify the **email type** (transactional / welcome / promo / win-back / newsletter) and **segment**
   → set tone and compliance rules.
2. Extract the **one goal + one CTA**; discard competing actions.
3. Write **3–5 subject-line variants** (≤~40 chars, value front-loaded) for A/B testing.
4. Write a **distinct preheader** (40–100 chars) that extends, never repeats, the subject.
5. Draft a **tight body**: hook line (shows in preview) → 1–3 value paragraphs → single CTA.
6. Ensure **unsubscribe + physical address** are present for promotional sends; keep the subject honest.

If `prompt.system` sets segment, sender name, or offer, honor it; otherwise default to a warm second-
person promo with one CTA. Emit labeled blocks (Subject variants / Preheader / Body / CTA / Footer).
Output is plain text or light markdown via the chat provider. Never write a deceptive subject or
fabricate urgency/subscriber counts — flag missing numbers rather than inventing them.

## See Also
- `ad-copy.md` — shares the front-load-the-first-40-chars discipline
- `marketing-copy.md` — the landing page the email CTA points to (message-match them)
- `seo-article.md`, `press-release.md` — sibling marketing genres
- `../use-case/document-processing.md` — chat-type text generation pipeline
