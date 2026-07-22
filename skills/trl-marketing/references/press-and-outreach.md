# Press and Outreach

Earned media for products without a PR budget: press kits, embargo mechanics, and newsletter/podcast/dev-advocate outreach. Realistic frame for a solo dev: TechCrunch is a lottery ticket; niche newsletters and podcasts are the actual game.

## Outreach Target Tiers

| Tier | Examples (dev-tool product) | Hit Rate | Worth It When |
|------|----------------------------|----------|---------------|
| **Niche newsletters** | Console.dev, TLDR (dev sections), Bytes, language/stack-specific letters | 10-30% with a good pitch | Always — highest ROI tier |
| **Podcasts** | Stack/niche dev podcasts, indie-hacker shows | 10-20%, longer lead time (4-8 weeks) | You can talk for 40 min about the domain |
| **YouTubers / streamers** | Dev-tool reviewers, live coders | 5-15% | Product demos well on video |
| **Dev advocates / micro-influencers** | 2k-50k-follower devs in your niche | 20-40% (they need content too) | You can offer early access + a genuine angle |
| **Aggregator/blog editors** | Changelog news, community blogs | 10-20% | You have a technical story, not just a product |
| **Mainstream tech press** | TechCrunch, The Verge | <2% without funding news | Funding, notable numbers, or trend hook only |

Build a list of 20-40 targets in `assets/project-tracker.md` (Outreach section). Qualify each: have they covered something like yours in the last 90 days? If not, cut.

## Press Kit

A single URL (e.g. `yoursite.com/press`) or shared folder. Journalists and newsletter writers spend <5 minutes; the kit's job is making the write-up effortless.

| Item | Spec |
|------|------|
| One-liner + paragraph | Straight from the message hierarchy — copy-pasteable |
| Fact sheet | Founder, launch date, pricing, platform support, notable numbers — bullet list |
| Screenshots/GIFs | 3-5, high-res, both light/dark if relevant, no marketing frames |
| Demo video | The 60-120s demo (`announcement-writing.md`) |
| Logo pack | SVG + PNG on transparent, light + dark variants |
| Founder photo + 2-line bio | For podcast/interview formats |
| Quotable claims | 3 pre-written quotes from you they can lift ("shipctl exists because…") |
| Contact | Email that you actually answer within hours during launch week |

## The Pitch Email

**Rules:** ≤120 words, no attachments (links only), subject line does the work, one clear ask, personalized first line proving you read their stuff.

**Template (newsletter pitch, fictional `shipctl`):**

> **Subject:** One-command deploy CLI, no YAML — launching Tuesday
>
> Hi [Name] — your issue on CI complexity creep last month nailed why I built this.
>
> shipctl deploys any repo to production in one command: it infers the build, emits a plain Dockerfile (no lock-in), and rolls back in 5 seconds. 1,200 deploys in beta, median first-deploy 90 seconds.
>
> Launching publicly Tuesday. Happy to give you early access now, or an exclusive angle if useful — 90-second demo: [link]. Press kit: [link].
>
> Either way, thanks for the newsletter.
> — Keith

**Follow-up:** one bump after 5-7 days ("floating this up — launch went well: front page of HN / #4 on PH"). Never a second bump.

## Embargo Mechanics

Embargoes ("you get this early; publish no sooner than date X") let multiple outlets cover launch day simultaneously. For solo-dev scale:

- Only bother when 3+ targets show interest pre-launch — otherwise just launch and pitch the results.
- State it explicitly in the email: "Embargoed until Tuesday July 21, 9am ET." An embargo is only binding once they *agree* — silence is not agreement; don't send secrets to someone who hasn't accepted.
- Give 3-7 days of lead time; include the full press kit so they can write without back-and-forth.
- Exclusives beat embargoes at small scale: offering one good newsletter the story first ("you'd be first to cover it") converts far better than coordinating five.

## Dev-Advocate / Influencer Outreach

Micro-influencers (2k-50k followers) in your niche move more qualified traffic than one big name. The trade is content, not money:

| You Offer | They Get |
|-----------|----------|
| Early access + white-glove onboarding | Content material before it's public |
| A genuine story/angle + demo assets | A post that writes itself |
| Founder availability for Q&A/stream guest | Interview content |
| Free tier / lifetime deal for their audience | Something to give followers |

**Sequence:** engage with their content genuinely for 1-2 weeks (reply, don't flatter) → DM/email with the pitch template above, adjusted to "thought your audience would care because [specific]" → deliver a frictionless experience → after launch, quote/amplify whatever they made.

**Disclosure:** anything paid or gifted-with-strings requires the creator to disclose (#ad / "sponsored") under FTC rules. Free access with no posting obligation generally doesn't, but let them disclose as they see fit — never ask anyone to hide a relationship.

## Outreach Timeline (Meshes with launch-checklist.md)

| When | Action |
|------|--------|
| T-30 | Build target list (20-40), start engaging with tier-4 advocates |
| T-21 | Press kit live; drafts of pitch variants per tier |
| T-14 | Send podcast pitches (longest lead time) |
| T-7 | Send newsletter/blogger pitches with embargo-or-exclusive offer |
| T-2 | Single follow-up bump to non-responders |
| T-0 | "We're live + early numbers" note to everyone who engaged |
| T+2 | Results-based pitch to non-responders ("front page of HN yesterday…") |
| T+7 | Log response rates in retro; prune dead targets |
