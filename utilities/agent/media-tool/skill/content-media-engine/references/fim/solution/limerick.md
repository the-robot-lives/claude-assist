# Limerick — five-line comic verse with a punchline

A limerick is a five-line comic poem with a strict AABBA rhyme and a bouncing
anapestic meter, built to deliver a punchline on line 5. The register is
whimsical, absurd, often bawdy — the humor is the point, and the tight meter is
what makes it *snap*. Good limericks land a genuine twist or pun on the last line
and keep the galloping rhythm; bad ones limp on broken meter, telegraph the
ending, or forget to be funny. Audience expects a laugh, a groan, or a wink — and
a rhythm they can clap along to.

**Output form**: plain text (5 lines)  **Typical length**: 5 lines
**Routed via**: `text_format: limerick` (chat-type generation)

## Genre Conventions & Structure

Five lines, rhyme scheme **AABBA**, in a predominantly **anapestic** meter
(da-da-DUM, two unstressed then one stressed):

```
Line 1 (A):  3 stressed beats (anapestic trimeter)   — sets up "There once was..."
Line 2 (A):  3 stressed beats  — rhymes with line 1
Line 3 (B):  2 stressed beats (dimeter, shorter)      — the complication
Line 4 (B):  2 stressed beats  — rhymes with line 3
Line 5 (A):  3 stressed beats  — rhymes with 1 & 2 — THE PUNCHLINE
```

So lines **1, 2, 5 are long** (3 beats) and rhyme together (A); lines **3, 4 are
short** (2 beats) and rhyme together (B). The shortened middle couplet speeds the
poem up and sets the timing for the payoff.

The canonical opening is a person + place ("There once was a X from Y") because
the place-name seeds an easy A-rhyme, but this is optional. **Line 5 must be the
funniest line** — the punch, twist, or pun.

Real example (Edward Lear, who popularized the form — note his line 5 often
echoes line 1 rather than twisting, the older style):

```
There was an Old Man with a beard,      (A)
Who said, "It is just as I feared!—      (A)
Two Owls and a Hen,                      (B)
Four Larks and a Wren,                   (B)
Have all built their nests in my beard!" (A)
```

Real example (anonymous, the modern twist-ending style — the meter is crisp
anapestic and the payoff lands on line 5):

```
There once was a man from Peru,          (A)
Who dreamed he was eating his shoe.      (A)
He woke with a fright                    (B)
In the middle of the night              (B)
To find that his dream had come true.    (A)
```

**Beat-mapping a real line.** Mark stresses (`/`) to hear the anapestic gallop and
the 3/3/2/2/3 contrast:

```
there ONCE was a MAN from peRU        / 3 beats
who DREAMED he was EA-ting his SHOE   / 3 beats
he WOKE with a FRIGHT                 / 2 beats
in the MID-dle of NIGHT               / 2 beats
to FIND that his DREAM had come TRUE  / 3 beats
```

Say it aloud: the DUMs fall in a rolling triple rhythm, and lines 3–4 are audibly
shorter. That contrast — long/long/short/short/long — is the limerick's skeleton.

## Hard Constraints

Checkable, non-negotiable:

1. **Exactly 5 lines.**
2. **Rhyme scheme AABBA** — lines 1, 2, 5 share one rhyme; lines 3, 4 share a
   different rhyme. Verify all five end-words.
3. **Beat structure 3 / 3 / 2 / 2 / 3** — lines 1, 2, 5 have three stressed
   beats; lines 3, 4 have two. This length contrast is mandatory (it *is* the
   limerick shape).
4. **Anapestic-dominant meter** (da-da-DUM). A limerick tolerates an iamb or an
   extra unstressed syllable at the start, but the galloping triple rhythm must
   be audible. Lines 1/2/5 typically run 8–9 syllables; lines 3/4 typically
   5–6 syllables.
5. **A punchline on line 5** — the last line carries the joke, twist, or pun.

## How-To (worked recipes)

### How to build the meter so it gallops
Write to the beat, not the syllable count. Chant "da-da-DUM da-da-DUM da-da-DUM"
for lines 1/2/5 and "da-da-DUM da-da-DUM" for lines 3/4. Fit words to that pulse:
"there ONCE was a MAN from peRU" = three DUMs. If a line stumbles when you say it
aloud, a stress is misplaced — swap word order or pick a word whose natural
accent falls on the beat.

### How to set up the A-rhyme for an easy landing
Choose the line-1 end-word knowing you need TWO more A-rhymes (lines 2 and 5).
Place-names and common nouns give rich rhyme families ("Peru/shoe/true/blue/who").
Avoid an end-word with almost no rhymes ("orange," "month") unless the whole joke
is the failure to rhyme it (a known meta-limerick gag).

### How to write a punchline that twists (not repeats)
Modern limericks reward a *turn* on line 5, not an echo of line 1. Draft the
absurd premise in lines 1–2, escalate/complicate in the short lines 3–4, then make
line 5 recontextualize it — the "dream had come true" flips "eating his shoe" from
silly to grim-funny. Don't reveal the joke early; protect the surprise for line 5.

### How to keep it clean or take it blue — on purpose
The register is a dial: whimsical-absurd (Lear) ↔ bawdy (the pub tradition). Read
the brief. If it's for a general/brand audience, keep it PG (wordplay, mild
mishaps). If it explicitly wants cheeky/adult, the innuendo lives in the line-5
twist. Either way the meter stays strict — sloppy rhythm kills the joke regardless
of content.

### How to use the short lines (3 & 4) as an accelerator
Lines 3 and 4 are fast and light — use them for the pivot/action that loads the
punchline ("He woke with a fright / In the middle of the night"). Don't waste them
on filler; they control the comic timing.

### How to repair a limping line
When a line thuds, the stress usually landed on the wrong syllable or a beat is
missing. Two fixes: (1) **reorder** so a naturally stressed syllable falls on the
beat ("a man who was living in Kent" → "there once was a fellow from Kent"); (2)
**swap a word** for one with the right stress shape — replace a two-syllable word
that fights the meter with a one- or three-syllable word that rides it. Re-chant
after every change; fix meter by ear, not by counting letters.

## Do's and Don'ts

### ✅ Do
- Hold AABBA and verify all five end-rhymes.
- Keep the 3/3/2/2/3 beat contrast — long, long, short, short, long.
- Land the joke on line 5.
- Chant it aloud to test the anapestic gallop.
- Use concrete, silly specifics (a named person/place/object).

### ❌ Don't
- **Don't break the meter** to fit a word — a limp line is instantly felt.
- **Don't make lines 3–4 the same length as 1–2** — the short couplet is essential.
- **Don't telegraph the punchline** in line 1 or 2.
- **Don't force the A-rhyme** with a nonsense word or a strained spelling.
- **Don't be earnest** — a solemn or sentimental limerick misses the genre entirely.
- **Don't run 6 lines or collapse to 4** — it's exactly 5.

## Tone, Voice & Register

Light, playful, mischievous. Third-person narration is the default ("There once
was..."), setting up a character to befall something ridiculous. Diction is
casual and punchy; the comedy comes from absurdity, wordplay, misdirection, and
the meter's momentum. Exclamation and dialogue are welcome (Lear loves them).
Emotion is comic, never sincere. Bawdiness is traditional but audience-gated.

## Platform / Placement Constraints

Plain text, 5 lines, line breaks preserved. Fits most cards/overlays since lines
are short — but the punchline must stay on its own line 5 to time correctly. No
markdown inside. If read aloud (voice/video briefs), the anapestic meter is a
feature — mark no special formatting, the rhythm carries it.

## Common Pitfalls & Anti-patterns (incl. AI-tells)

- **Meter collapse.** LLMs nail the AABBA rhyme but flatten the anapestic gallop
  into prose with rhymes. Chant every line; if it doesn't bounce, it's not a
  limerick.
- **Equal-length lines.** Making all five lines the same length destroys the shape.
  Lines 3–4 MUST be visibly shorter (2 beats).
- **No actual joke.** A grammatically perfect AABBA that isn't funny fails the
  genre. Line 5 needs a payoff.
- **Telegraphed ending** — line 2 gives away the punchline, so line 5 lands flat.
- **Forced/strained rhymes** and torturing spelling to fake a rhyme
  ("Peru / kanga-roooo").
- **Sentimentality or moralizing** — limericks don't do sincere life lessons.
- **The tired "There once was a X from Nantucket/Peru" with a stale payoff** —
  fine as scaffolding, but the joke must still be fresh.
- **AI over-politeness** — sanitizing the humor into a toothless observation. A
  limerick needs an edge (silly or cheeky), not a wholesome affirmation.

## Prep-Agent Notes (media-tool specific)

From the raw creative brief:
1. **Find the comic premise** and the intended punchline/twist. If the brief has a
   subject but no joke, invent the absurd turn and put it as the line-5 target.
2. **Set the register from the audience** (brand/PG vs cheeky/adult) and state it
   in the generation prompt — this gates the humor.
3. **State the constraints explicitly**: "5 lines, AABBA, anapestic, lines 1/2/5 =
   3 beats and lines 3/4 = 2 beats, punchline on line 5." Naming the beat pattern
   fixes the most common failure (equal-length lines).
4. **Seed an easy A-rhyme** — if the brief names a place/name, suggest it as the
   line-1 end-word so lines 2 and 5 have rhymes to reach for.
5. **Instruct to protect the punchline** (don't reveal it before line 5) and to
   read the draft aloud for meter.
6. Fold `prompt.system` art-direction into the *subject and joke*, not into extra
   lines — it's exactly 5.
7. Output is plain text via the chat provider path.

## See Also
- `haiku.md`, `sonnet.md`, `epic-poem.md` (sibling fixed-form verse)
- `short-story.md` (prose narrative contrast)
- `../use-case/document-processing.md`
