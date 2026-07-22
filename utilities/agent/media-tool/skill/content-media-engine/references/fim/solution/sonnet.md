# Sonnet — 14-line argument with a turn

A sonnet is a fourteen-line poem in iambic pentameter that develops a single
idea, image, or feeling and then *turns* on it. The pleasure of the form is
watching a tight argument build across the rhymed quatrains and then pivot at the
volta — a resolution, reversal, or complication. Good sonnets earn their turn and
land the final rhyme; bad sonnets pad lines to fill the meter, force rhymes
("love / above / thereof"), or reach 14 lines with no argument and no turn.
Audience expects both the scaffolding (rhyme + meter) and the intellectual move.

**Output form**: plain text (14 lines, optional stanza breaks)  **Typical length**: 14 lines
**Routed via**: `text_format: sonnet` (chat-type generation)

## Genre Conventions & Structure

Fourteen lines of **iambic pentameter** (10 syllables, five da-DUM feet per line)
built on one of two dominant rhyme architectures:

**Shakespearean (English) sonnet** — three quatrains + a couplet:

```
Rhyme scheme:  a b a b   c d c d   e f e f   g g
Structure:     Q1        Q2        Q3        Couplet
Volta:         usually at line 9 (start of Q3) OR at the couplet (line 13)
```

The three quatrains present an argument/image in stages; the closing **couplet**
delivers the epigrammatic turn, summary, or twist. Real opening (Shakespeare 18),
scan the iambic beat and the abab:

```
Shall I compare thee to a summer's day?   (a)
Thou art more lovely and more temperate:  (b)
Rough winds do shake the darling buds of May, (a)
And summer's lease hath all too short a date; (b)
```

**Petrarchan (Italian) sonnet** — an octave + a sestet:

```
Rhyme scheme:  a b b a  a b b a   ‖   c d e c d e  (or c d c d c d, c d e d c e)
Structure:     Octave (8)         ‖   Sestet (6)
Volta:         at line 9, the octave/sestet hinge
```

The **octave** poses a problem, question, or situation; the **volta** at line 9
turns; the **sestet** answers or resolves it. The octave rhyme is fixed
(abbaabba); the sestet is flexible — common schemes: `cdecde`, `cdcdcd`,
`cdccdc`. Avoid ending the sestet on a couplet (that reads Shakespearean).

Real Petrarchan example (Wordsworth, "The world is too much with us") — the octave
`abbaabba`, the volta at line 9 ("Great God!"), then the sestet:

```
The world is too much with us; late and soon,   (a)
Getting and spending, we lay waste our powers;— (b)
Little we see in Nature that is ours;            (b)
We have given our hearts away, a sordid boon!    (a)
...
Great God! I'd rather be                         (volta, line 9)
A Pagan suckled in a creed outworn;
```

**The volta (turn)** is the defining craft element of *both* types — a shift in
direction signalled by "But," "Yet," "And yet," "So," "Then," or a change of
tense/address/argument. A sonnet without a volta is just 14 rhymed lines.

**Scansion — reading the iambic beat.** Iambic pentameter = five iambs
(da-DUM) per line. Mark stresses to check a line scans:

```
Shall I | com-PARE | thee TO | a SUM | mer's DAY?
  x  /  |  x   /   |  x   /  |  x  / |   x    /
```

Five stressed beats (`/`), ten syllables, unstressed-stressed throughout. A common
*legal* variation is a **trochaic first foot** (DUM-da) for emphasis, or a
**feminine ending** (an extra unstressed 11th syllable). Test by tapping: if you
can't find five clean beats, the line is off-meter.

## Hard Constraints

Checkable, non-negotiable:

1. **Exactly 14 lines.**
2. **Iambic pentameter** — 10 syllables per line, unstressed-STRESSED ×5. Minor
   substitutions (an opening trochee, a feminine 11th-syllable ending) are
   permissible and traditional, but the base is 10-syllable iambic.
3. **A consistent rhyme scheme**, one of:
   - Shakespearean: `abab cdcd efef gg`
   - Petrarchan: octave `abbaabba` + sestet `cdecde` / `cdcdcd` / `cdccdc`
   Rhymes must be true or near-true; the letters must actually match sound.
4. **A volta** — a discernible turn, at line 9 (both types) or the couplet
   (Shakespearean).
5. **Single unified subject** — one argument/image developed, not 14 lines of
   unrelated statements.

## How-To (worked recipes)

### How to plan the argument to the rhyme architecture
Outline before writing: Shakespearean → 3 beats + a punchline (Q1 states, Q2
develops, Q3 complicates, couplet resolves/twists). Petrarchan → problem (octave)
then answer (sestet). Assign one idea per unit so the rhyme scheme carries
structure, not just sound.

### How to hit iambic pentameter without wooden filler
Choose words whose natural stress *is* iambic; don't inject "doth / oft / e'er"
to pad. Test each line: "and SUM-mer's LEASE hath ALL too SHORT a DATE" — five
clean beats. If a line runs 11 syllables, either accept a deliberate feminine
ending or cut a weak word ("very," "quite," "just"). Read aloud; count feet, not
just syllables.

### How to land the volta
Mark the turn with a signal word at the exact structural seam. Shakespearean at
line 13: "But thy eternal summer shall not fade..." (Sonnet 18's couplet turn).
Petrarchan at line 9: "Yet..." / "And yet..." Make the *content* actually change
direction — a real reversal or resolution, not a restatement.

### How to find rhymes without forcing them
Pick the rhyme-pair END-word that carries the most meaning first (the one you
*need*), then build the line toward it — don't write the line and then hunt a
rhyme for a throwaway final word. If the only rhyme is a cliché ("love/above,"
"heart/apart," "fire/desire"), rewrite the *earlier* line so a fresher end-word
is available. Near/slant rhyme ("stone/gone," "prove/love") is acceptable and
often stronger than a forced perfect rhyme.

### How to open strong
Line 1 should state the subject or pose the question with a concrete hook
("When, in disgrace with fortune and men's eyes..."), not a throat-clear ("I want
to write about the way that love..."). The first line sets the meter contract.

## Do's and Don'ts

### ✅ Do
- Commit to ONE scheme (Shakespearean or Petrarchan) and hold it for all 14 lines.
- Build a real argument that turns at the volta.
- Keep iambic pentameter; allow classic substitutions sparingly.
- Choose meaningful rhyme-words and build lines toward them.
- Vary sentence length across lines so syntax plays against the meter.

### ❌ Don't
- **Don't drift the scheme** (start abab then wander) — pick one and verify every
  end-word.
- **Don't skip the volta** — 14 rhymed lines with no turn is not a sonnet.
- **Don't force rhymes** with archaic filler ("'tis," "doth," "e'er," "ope'") just
  to fit — it dates the poem and signals padding.
- **Don't stuff syllables** ("oh so very," "the which," "unto") to reach 10.
- **Don't end-stop all 14 lines** — enjambment keeps the argument moving.
- **Don't let the couplet merely repeat** the quatrains — it must resolve or twist.

## Tone, Voice & Register

Elevated but not necessarily archaic — a modern sonnet can use contemporary
diction and still scan. First person is common (the sonnet's roots are the
love-lyric and the meditation), but second-person address ("thou/you") and
third-person argument are all valid. Register is deliberate, controlled,
rhetorical: the form itself is a display of wit and structure. Emotion is
channeled through argument, not spilled. Avoid faux-Elizabethan cosplay unless the
brief asks for pastiche.

## Platform / Placement Constraints

Plain text, 14 lines. Optionally mark stanza breaks with a blank line
(quatrain/quatrain/quatrain/couplet, or octave/sestet) to make structure visible.
No markdown emphasis inside the poem. If rendered on an image/card, note that 14
pentameter lines rarely fit — a sonnet is a page-length artifact, not an overlay.

## Common Pitfalls & Anti-patterns (incl. AI-tells)

- **Rhyme-scheme collapse.** LLMs often start `abab` and then produce lines that
  don't actually rhyme by line 8. Verify each labeled pair aloud.
- **Meter mush.** Claiming iambic pentameter while producing 8- or 12-syllable
  lines. Count feet on every line.
- **The forced-rhyme graveyard**: love/above/dove, heart/apart/depart,
  fire/desire, night/light/bright, sky/high/why. Overused perfect rhymes read as
  AI-generated. Prefer fresher or slant rhymes.
- **No volta.** The most common structural failure — a pretty 14 lines that never
  turns. Insist on the pivot.
- **Archaic-word padding** ("doth," "'tis," "o'er," "hath," "thee/thou" sprinkled
  randomly) used only to make syllables fit — a dead giveaway of a meter patch.
- **Couplet-as-summary cliché**: "And so my love for you will never end, / until
  the very stars from heaven descend." Hollow, over-rhymed, no twist.
- **"Delve," "tapestry," "testament," "symphony," "dance"** — LLM poeticism
  crutches. Ban them.
- **Uniform end-stopping** — every line a complete sentence — makes the poem
  plod. Use enjambment.

## Prep-Agent Notes (media-tool specific)

From the raw creative brief:
1. **Pick the sonnet type.** Default to **Shakespearean** (easier rhymes in
   English, familiar couplet punch) unless the brief wants a problem→resolution
   meditation (→ Petrarchan) or names a type.
2. **Extract the single subject** and shape a mini-argument arc: Q1/Q2/Q3/couplet
   (Shakespearean) or octave-problem/sestet-answer (Petrarchan). Put this arc in
   the generation prompt.
3. **State the constraints explicitly in the prompt**: line count (14), the exact
   rhyme scheme letters, iambic pentameter, and *where the volta falls*. Naming the
   scheme letters (`abab cdcd efef gg`) sharply improves adherence.
4. **Require a volta** and name its signal ("turn at line 9 with 'But/Yet'").
5. **Forbid archaic filler and cliché rhyme pairs** in the prompt.
6. Fold `prompt.system` mood/imagery into the argument's content and imagery, not
   into extra lines — the line count is fixed at 14.
7. Output is plain text via the chat provider path.

## See Also
- `haiku.md`, `limerick.md`, `epic-poem.md` (sibling fixed-form verse)
- `short-story.md` (prose narrative contrast)
- `../use-case/document-processing.md`
