# Haiku — compressed seasonal image in 5-7-5

A haiku is a three-line, seventeen-syllable poem that fixes a single perceived
moment in nature or daily life. Its craft is subtraction: no title, no rhyme,
no explanation, no metaphor-for-its-own-sake. Good haiku shows one image (often
two juxtaposed images) and trusts the reader to feel the resonance; bad haiku
tells the reader how to feel, pads syllables with filler, or reads like a
greeting-card aphorism chopped into three lines. Audience expects restraint and
a concrete sensory anchor, not a "deep thought."

**Output form**: plain text (3 lines)  **Typical length**: 3 lines, 17 syllables
**Routed via**: `text_format: haiku` (chat-type generation)

## Genre Conventions & Structure

The English-language haiku inherits its rules from Japanese *haikai*, adapted:

- **Three lines**, arranged **5 / 7 / 5 syllables** (line 1 = 5, line 2 = 7,
  line 3 = 5). This is the English convention. (Japanese counts *on* / mora, not
  syllables — see Pitfalls — but for `text_format: haiku` the 5-7-5 syllable
  count is the checkable target unless the brief explicitly asks for free-form.)
- **Kigo (季語) — a season word.** A concrete image that fixes the poem in a
  season: "cherry blossom" / "snow" (spring/winter), "cicada" / "heat"
  (summer), "harvest moon" / "falling leaves" (autumn). The kigo is the single
  most important convention — it roots the poem in the natural cycle.
- **Kireji (切れ字) — a cutting word.** A break that splits the poem into two
  juxtaposed parts, usually after line 1 or line 2. English has no grammatical
  kireji, so we render it with punctuation (em dash, colon, ellipsis, period) or
  a hard syntactic turn. The cut creates the "leap" between two images.
- **Two-image juxtaposition.** The strongest haiku set one image against another
  and let the friction between them do the work (a wide image + a narrow one; a
  vast season + a small event).
- **Present tense, sensory, concrete.** Haiku happens *now*, in front of you.
- **No title.** Haiku are untitled by convention.
- **No end-rhyme, no regular meter beyond the syllable count.**

Classic structure: **fragment + phrase** — one short line that stands alone (the
"fragment," the cut image) and two lines that complete a second image (the
"phrase"). The fragment can be line 1 or line 3.

Real example (Bashō, trans. Robert Hass) — note the cut after line 1 and the
juxtaposition of the still old pond against the sudden splash:

```
The old pond—
a frog jumps in,
sound of water
```

Real example (Buson) — autumn kigo ("autumn"), the cut after line 2:

```
Coolness—
the sound of the bell
as it leaves the bell
```

## Hard Constraints

These are checkable. The generated haiku MUST satisfy:

1. **Exactly 3 lines.**
2. **Syllable counts 5 / 7 / 5** (17 total). Count by spoken English syllables.
   Contractions count as written ("doesn't" = 2). If the brief requests a
   free-form / "modern" haiku, relax to **≤17 total, short-long-short**, but
   default to strict 5-7-5.
3. **No end-rhyme** across the three lines.
4. **No title.**
5. **Present tense** (no past-tense narration of a completed event unless the
   image genuinely requires it).
6. **At least one concrete seasonal or nature image** (the kigo). No pure
   abstraction ("love is eternal / hope springs in the human / heart forever").
7. **A cut** — a discernible break/juxtaposition between two parts, marked by
   punctuation or syntax.

## How-To (worked recipes)

### How to hit 5-7-5 without padding
Draft the image first, then *count and trim*, don't count and stuff. If line 1
is 4 syllables, don't insert "the" or "a" to pad — find a richer noun. Bad
(padded to 5): "the very cold snow". Good (5, concrete): "first frost tonight".
Read each line aloud and tap syllables on the table; LLMs miscount silently.

### How to choose and place a kigo without forcing it
Pick the season implied by the brief, then choose ONE concrete image that a
person would actually notice in that season — not the most clichéd one.
Autumn brief → not "falling leaves" (overused) but "the last cricket" or
"woodsmoke." Place it where it can anchor a whole line. Note: one kigo per
haiku; two competing season words muddy the poem.

### How to make the cut (kireji) land
Write two images, then decide which one gets the solo line. Put the em dash /
colon / period right at the seam. Example: "Migrating geese— / I too am leaving
/ this small town." The dash after "geese" is the cut; the vast image (geese)
juxtaposes the small human one. Don't cut in the middle of a single continuous
thought — that's just a line break, not a *kire*.

### How to show without commenting
Delete every word that interprets the image. If you wrote "the lonely moon / makes
me feel so sad tonight / empty like my heart," strip the feeling-words and keep
the image that *causes* the feeling: "winter moon— / one bowl, one pair
of / chopsticks on the table." The loneliness is now shown, never named.

### How to end on the image, not the moral
The third line should deliver a final concrete sensation, not a conclusion.
End on "cold rain on the rail," not "and so life passes by."

## Do's and Don'ts

### ✅ Do
- Anchor in one concrete sensory image (sight, sound, touch, smell).
- Include a season word (kigo).
- Juxtapose two images and mark the cut with punctuation.
- Use present tense and plain, common words.
- Count syllables aloud; verify 5-7-5 before emitting.
- Trust the reader — leave the resonance unstated.

### ❌ Don't
- **Don't rhyme the lines** — end-rhyme signals a limerick/greeting card, not a haiku.
- **Don't add a title** — haiku are untitled.
- **Don't state the emotion** ("so beautiful," "I feel peaceful") — show the image
  that produces it; naming the feeling breaks the form.
- **Don't use simile/metaphor as decoration** ("clouds like cotton candy") — haiku
  presents the thing itself, not a comparison.
- **Don't pad to reach syllable counts** with "the / a / very / so / really."
- **Don't cram a full narrative** — one moment, not a story with before/after.
- **Don't write abstraction only** (love, time, hope) with no image to hold it.

## Tone, Voice & Register

Quiet, observational, impersonal-yet-intimate. The "I" is usually absent or a
faint presence; the poem points outward at the world. Vocabulary is plain and
common — haiku distrusts fancy words. No exclamation marks (the punch comes from
the image, not typography). Third-person or an unobtrusive first-person witness.
Present tense, active perception. Humor exists (see *senryū*, haiku's comic
cousin about human foibles) but the default register is contemplative.

## Platform / Placement Constraints

Plain text, three lines, hard line breaks preserved. Renders anywhere. If the
`.media.prompt` targets a card/image overlay, keep the total under ~40 characters
per line so it fits typical layouts. No markdown formatting inside a haiku —
italics/bold are noise here.

## Common Pitfalls & Anti-patterns (incl. AI-tells)

- **Syllable drift.** The #1 LLM failure: the model *claims* 5-7-5 but miscounts
  (treats "flower" as 1, "fire" as 2, etc.). Always recount aloud. "Every" is 2
  or 3 depending on dialect — avoid ambiguous words.
- **Rhyming haiku.** LLMs default to rhyme because "poem" primes it. Haiku does
  not rhyme.
- **The stated moral / greeting-card ending.** "...and life goes on" / "...reminding
  us to breathe." Delete it.
- **Abstraction soup.** "Time's endless river / flows through eternity's vast /
  ocean of the soul." No image, no kigo, no cut — this is not a haiku.
- **Overused kigo.** Cherry blossoms + full moon + falling leaves in every output.
  Reach for the specific: "the first mosquito," "melting snow at the curb."
- **Titles / "Haiku:" prefixes / trailing signatures.** Emit only the three lines.
- **Adjective stacking** ("beautiful golden shimmering leaves") — one precise noun
  beats three vague adjectives.
- **The em-dash everywhere.** One cut per poem. Don't dash every line.

## Prep-Agent Notes (media-tool specific)

From the raw creative brief:
1. **Extract or infer the season** → choose ONE kigo (prefer a specific, non-clichéd
   image over the obvious one).
2. **Identify the core moment / two images** the user wants juxtaposed → decide
   which becomes the solo (cut) line.
3. **Set the constraint block in the generation prompt explicitly**: "3 lines,
   5-7-5 syllables, present tense, no rhyme, no title, one season word, one cut
   marked with punctuation." Restating the count in the prompt materially reduces
   syllable drift.
4. **Instruct: show, don't tell** — forbid feeling-words and morals.
5. Fold `prompt.system` art-direction (mood, imagery palette) into the *choice of
   image*, not into added commentary lines.
6. If the brief wants multiple haiku (a sequence / *renga*-like set), tell the
   generator to keep each independently valid 5-7-5 and vary the kigo.
7. Output is plain text via the chat provider path — no code fences, no metadata,
   just the three lines.

## See Also
- `sonnet.md`, `limerick.md`, `epic-poem.md` (sibling fixed-form verse)
- `short-story.md` (prose narrative contrast)
- `../use-case/document-processing.md`
