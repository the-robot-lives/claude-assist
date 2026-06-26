# Flywheel Social

> A Discord-style interest network that grows your world instead of shrinking it.

Flywheel is a community chat platform organized around **interest channels** — but
unlike a typical server where everyone in a channel sees everyone, what you see on
Flywheel is shaped by your personal social graph and a deliberate dose of
serendipity. The result is a feed that keeps you close to the people and ideas you
already love, while steadily and respectfully exposing you to new — and even
opposing — ones.

The name says the goal: a **flywheel**. The more you connect, the more the network
expands; the more it expands, the more good content and new perspectives it
surfaces; and that, in turn, gives you reasons to connect further.

---

## The core idea: your graph of mutuals

Connections on Flywheel are **mutuals** (in-app term: *moots*). Mutuals are
symmetric — you both opted in — and they form a web that radiates outward in
degrees:

- **1st degree** — your direct mutuals
- **2nd degree** — mutuals of your mutuals
- **3rd / 4th degree** — and outward, with influence decaying at each hop

Your distance from someone in this web governs how much of their activity reaches
you. You see *everything* from direct mutuals, and progressively only
**interest-relevant** content as you move outward. Closer hops carry slightly more
weight when ranking what to show, so a 2nd-degree mutual's post on a shared interest
will tend to surface before a 4th-degree one.

---

## What you see in a channel: three lanes

Inside an interest channel, the people whose posts you can encounter fall into three
distinct lanes.

### 1. Your mutuals network (full interaction)

The web of mutuals — direct, 2nd, 3rd, 4th degree. You can **chat and interact**
freely here. You see all posts from direct mutuals, and interest-filtered posts from
the degrees beyond.

### 2. Swipe-to-match (grow the web)

People you don't yet know but who **share an interest** with you. Flywheel surfaces
them in a swipe interface (Tinder-style) keyed on subject-matter overlap:

- **Swipe right** to express interest. The other person can then choose to see *your*
  posts (but not your mutuals' posts). You **cannot** see theirs yet — it's
  one-directional until reciprocated.
- If they **accept**, you become mutuals, and the web expands by one — pulling their
  network into your reachable degrees.

This is the primary engine of growth: every accepted match widens the graph and the
range of content and people it can surface.

### 3. Opposing views (read-only, by design)

A bounded stream of posts from people who hold **different views than you** on a
subject you both care about. You can **see but not respond** to these. Only a fixed
ratio of such posts appears, and only *specific* posts — not everything a given
person writes — as long as the topic intersects an interest of yours.

> Example: you love pineapple on pizza *and* football. You'll occasionally see
> football posts from other football fans who happen to hate pineapple on pizza —
> people you'd never otherwise cross paths with, surfaced because of what you share,
> not just what you agree on.

---

## The discovery engine

Beyond posts inside your stated interests, Flywheel deliberately mixes in content
that is **adjacent to** or **different from** what you've declared — until you signal
disinterest.

- Exposure **rotates** over time so you're not flooded. If you like set theory, one
  month you might see topology posts, the next month analysis. Like cars? One month
  you'll see a few cyclists' posts.
- All discovery still flows **through the mutuals web** — out to 4th-degree mutuals
  only. New ideas arrive via people connected to people you chose, not from strangers
  at random.

**Why this matters:** if you mutual someone because you both like frisbee, you'll
see their posts — and one day that includes a post on how much they hate sushi, which
you love. Suddenly an idea that opposes your own arrives through a connection you
actually value. Flywheel joins people by **both their shared beliefs and their
differences.**

---

## Safety and controls

Exposure to opposing views is intentional — but it is **opt-out, scoped, and
enforced**.

- **Exclude interests or beliefs.** You can remove specific topics or stances from
  your discovery and opposing-views lanes entirely (e.g. exclude anti-trans content).
  These exclusions are mutual: an excluded party also stops seeing *your* tagged
  posts, and the block propagates through the outer degrees of the web for tagged
  content.
- **Block individuals.** When you block someone you choose whether the block also
  covers the *outer* degrees of their network — mutuals-of-mutuals (and beyond) who
  reach you *through* them. Your **direct** mutuals are never severed by this, though
  you'll still be able to tell they are mutuals of the blocked person.
- **State a dislike** on any surfaced interest to stop that thread of discovery.

---

## Visibility rules at a glance

| Relationship                          | What you see                                  |
|---------------------------------------|-----------------------------------------------|
| Direct mutual                         | All of their posts                            |
| 2nd–4th degree mutual                 | Only posts within your shared interests       |
| Swiped (not yet reciprocated)         | Nothing yet; they may opt to see *your* posts |
| Opposing-view participant             | A fixed ratio of topic-relevant posts only — read-only |
| Discovery (adjacent / opposing ideas) | Rotating sample, via ≤4th-degree mutuals       |
| Excluded interest / blocked party     | Nothing (block can cascade through outer degrees) |

---

## Why Flywheel

Most social feeds optimize for agreement and engagement, which tends to narrow what
each person sees over time. Flywheel optimizes for a healthier loop: keep people
close to what they love, use real human connections (not anonymous firehoses) as the
conduit, and lean on shared interests to make exposure to *different* and *opposing*
ideas feel earned rather than imposed — always under the user's control.

Connect → the web grows → better content and new perspectives surface → you connect
further. That's the flywheel.

---

## Status

Early concept / design stage. This README captures the product vision and core
mechanics; architecture, data model, and implementation are not yet defined.
