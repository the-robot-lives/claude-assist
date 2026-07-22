# Epic Poem — elevated long-form heroic narrative

An epic poem is a long narrative poem in an elevated register that recounts the
deeds of a hero (or a people) against a vast, often cosmic, backdrop. Its craft
is the opposite of the haiku's: expansion, grandeur, formal machinery. The epic
opens by invoking a muse, plunges the reader *in medias res* (into the middle of
the action), and sustains a grand style through recurring devices — epic similes,
catalogues, fixed epithets, and a steady metrical line. Good epic verse sustains
elevation and momentum across many lines; bad epic verse either collapses into
flat prose-with-line-breaks or bloats into empty grandiosity with no story moving.
Audience expects sweep, formality, and forward narrative drive.

**Output form**: plain text (many lines; may use verse-paragraph / stanza breaks)
**Typical length**: an excerpt/canto (dozens to a few hundred lines) unless the brief bounds it
**Routed via**: `text_format: epic-poem` (chat-type generation)

## Genre Conventions & Structure

The epic assembles a recognizable set of conventions ("epic machinery"):

- **Invocation of the Muse.** The poem opens by calling on a Muse (or god,
  power, spirit) to sing/tell the tale, and *states the theme* up front. Homer:
  "Sing, O goddess, the anger of Achilles..."; Milton: "Sing, Heavenly Muse..."
- **Statement of theme (propositio).** Announce the subject in the first lines
  ("Of Man's first disobedience... sing").
- **In medias res.** Begin in the middle of the action, not at the chronological
  start; fill in earlier events later via flashback/retrospect.
- **Elevated register / grand style.** Formal, dignified diction; long periodic
  sentences; apostrophe and rhetorical address.
- **Epic (Homeric) simile.** Extended similes that unfold over several lines,
  comparing a heroic action to something from nature or daily life ("As when a
  lion... so did the hero...").
- **Catalogues.** Formal lists — of ships, warriors, forces, ancestries — that
  convey scale.
- **Epithets.** Fixed descriptive tags repeated with names: "swift-footed
  Achilles," "grey-eyed Athena," "the wine-dark sea," "rosy-fingered Dawn."
- **Vast setting & high stakes.** National, cosmic, or mythic scope; gods or fate
  intervene; the fate of peoples hangs on the hero.
- **Deeds of a hero of great stature** embodying cultural values.

**Meter (choose one and hold it):**

- **Dactylic hexameter** — the classical epic line (Homer, Virgil): six feet, each
  a dactyl (DUM-da-da) or spondee (DUM-DUM), the fifth foot usually a dactyl and
  the last a spondee/trochee. Hard to sustain naturally in English.
- **Blank verse** — unrhymed **iambic pentameter** (Milton's *Paradise Lost*): the
  workhorse of English epic; 10 syllables, da-DUM ×5, no rhyme. **Recommended
  default for English** — it carries elevation without forcing rhyme.
- **Iambic couplets / ottava rima / Spenserian stanza** — rhymed options (Pope's
  Homer uses heroic couplets; Byron's *Don Juan* uses ottava rima abababcc). Use
  only if the brief wants rhyme.

Real opening (Milton, *Paradise Lost*, Book I — invocation + theme + blank verse):

```
Of Man's first disobedience, and the fruit
Of that forbidden tree whose mortal taste
Brought death into the World, and all our woe,
With loss of Eden, till one greater Man
Restore us, and regain the blissful seat,
Sing, Heavenly Muse...
```

Real epic-simile shape (Homer, *Iliad*, pattern): "As when a lion, ranging the
hills in hunger, springs upon the herds — so Diomedes fell upon the Trojans." The
"As when... so..." frame is the signature.

Real extended simile (Milton, *Paradise Lost* I — the fallen Satan's shield;
note how the vehicle wanders for lines before returning):

```
       ...his ponderous shield
Ethereal temper, massy, large and round,
Behind him cast; the broad circumference
Hung on his shoulders like the Moon, whose Orb
Through Optic Glass the Tuscan Artist views
At Ev'ning from the top of Fesole...
```

Catalogue example (the device, not a quote): a formal muster — "First came the men
of Argos, bronze-clad, forty ships; / and after them the Spartans under Menelaus..."
— a list that conveys scale and roots the tale in a named world.

## Hard Constraints

Checkable where verse-craft allows:

1. **An invocation and theme-statement in the opening lines** (call to a
   muse/power + announce the subject).
2. **In medias res** — the narrative opens mid-action, not at a chronological
   "once upon a time" start (unless the brief overrides).
3. **A single, consistent meter** for the whole passage — default **blank verse
   (unrhymed iambic pentameter, 10 syllables/line)** unless the brief names
   dactylic hexameter or a rhymed stanza. Do not switch meters mid-poem.
4. **At least one epic simile** ("As when... so...") if length permits.
5. **Fixed epithets** attached to major names, reused across the passage.
6. **Elevated register throughout** — no casual/modern slang breaking the tone.
7. **Sustained narrative** — the passage must *advance an action*, not merely
   describe.

## How-To (worked recipes)

### How to open with an invocation that isn't padding
Invoke AND inform in the same breath: name the power you call on *and* the theme
you'll sing. Milton names the disobedience and the fruit inside the invocation.
Bad (padded): "O Muse, O great and mighty Muse, I call to thee, O Muse divine,
please help me sing this tale..." — three lines of throat-clearing. Good: state
the subject *as* you invoke.

### How to write an epic (Homeric) simile
Use the "As when... so..." frame. Take a heroic moment, then compare it to a
vivid, everyday or natural vignette that unfolds for 3–6 lines before snapping
back with "so": "As when a farmer, at the fall of night, drives home his weary
oxen through the mud, / so Ajax, spent and streaked with dust, withdrew." The
tenor (hero) and vehicle (farmer) illuminate each other; the length is the point.

### How to deploy epithets without them becoming filler
Give each major figure ONE or two fixed tags and reuse them at natural metrical
slots ("swift-footed Achilles," "cloud-gathering Zeus"). They aid the meter and
signal the oral-epic tradition. Don't invent a new flowery epithet every line —
the power is in the *repetition*.

### How to sustain blank verse (the default)
Write in unrhymed iambic pentameter and lean on **enjambment** and **periodic
syntax** — let sentences run across several lines and land the verb/climax late.
This is what gives Milton his roll. Vary the caesura (mid-line pause) so lines
don't clack uniformly. Count 10 syllables per line; allow the occasional
substitution but keep the iambic base.

### How to enter in medias res and backfill
Open at a charged moment (a battle joined, a hero already exiled, the fleet
already storm-tossed). Then, a little later, have a character *narrate* the prior
events (Odysseus recounting his wanderings at Alcinous's court). Don't start at
the chronological beginning.

### How to keep grandeur from becoming empty bombast
Elevation must ride on *concrete action and image*, not adjective stacks. "The
bronze-tipped spear tore through the shield and drank his blood" beats "the mighty
glorious magnificent warrior of great and awesome power." Grand style + concrete
verbs = epic; grand style + abstraction = bloat.

## Do's and Don'ts

### ✅ Do
- Open with invocation + theme, in medias res.
- Hold one meter (default blank verse) throughout.
- Use extended "As when... so..." similes.
- Attach and reuse fixed epithets.
- Keep the narrative *moving* — advance the deed.
- Use periodic sentences and enjambment for momentum.

### ❌ Don't
- **Don't switch meters** mid-passage or drift into prose-with-line-breaks.
- **Don't pad the invocation** with repeated "O Muse" filler.
- **Don't stack empty superlatives** ("mighty, glorious, awesome, powerful") in
  place of concrete action.
- **Don't modernize the register** with slang or casual asides (breaks the epic
  frame unless the brief wants mock-epic).
- **Don't just describe** a static scene for pages — an epic narrates.
- **Don't rhyme** if you chose blank verse (Milton is unrhymed) — mixing in
  accidental couplets cheapens it.

## Tone, Voice & Register

Elevated, formal, resonant. Third-person narrator of vast authority (or the
Muse's voice). Diction is dignified and can be lightly archaic, but grandeur comes
from *syntax and image*, not from sprinkling "thee/doth." Apostrophe (direct
address to gods, the dead, abstractions) and rhetorical questions belong here.
Emotion is public and heightened — grief, rage, glory, fate — not private
confession. Momentum matters: even in grandeur, the story drives forward.

## Platform / Placement Constraints

Plain text, many lines; may use verse-paragraph or stanza breaks (blank line
between movements). Long-form — not for cards/overlays. If the brief bounds
length, deliver a coherent *excerpt* (an opening invocation + one scene, or a
single canto) rather than a truncated fragment that stops mid-sentence. Preserve
line breaks exactly.

## Common Pitfalls & Anti-patterns (incl. AI-tells)

- **Prose in disguise.** The most common LLM failure: flat sentences chopped into
  arbitrary line lengths with no meter. Enforce the chosen meter (count syllables).
- **Bombast without story.** Pages of grand adjectives while nothing *happens*.
  Every verse-paragraph should advance the action.
- **Invocation bloat.** "O Muse, O Muse, O heavenly Muse, I beg thee, sing to me,
  O Muse..." Say it once, with the theme.
- **Adjective avalanches** — "the mighty, powerful, glorious, fearsome, valiant
  hero." One precise epithet beats five vague ones.
- **Meter drift / accidental rhyme** in what should be blank verse.
- **Modern intrusions** — a casual phrase or anachronism puncturing the elevated
  frame.
- **AI poeticisms**: "tapestry of fate," "dance of destiny," "symphony of war,"
  "delve into the depths," "testament to." These crutch-phrases read as generated;
  ban them.
- **Similes that never leave the frame** — a bare "like a lion" is not an epic
  simile; it must *extend* ("As when a lion...").
- **Stopping mid-thought** to hit a length cap — end on a completed movement.

## Prep-Agent Notes (media-tool specific)

From the raw creative brief:
1. **Identify the hero, the deed, and the stakes** (personal → national → cosmic).
   Put the theme statement into the generation prompt so the invocation can name it.
2. **Choose the meter.** Default **blank verse (unrhymed iambic pentameter)** for
   English; use dactylic hexameter or a rhymed stanza only if the brief asks.
   State the choice explicitly in the prompt.
3. **Set the opening as in-medias-res** — tell the generator the charged moment to
   start on, and what earlier events get backfilled later.
4. **Assign 1–2 fixed epithets** per major figure and instruct their reuse.
5. **Require at least one extended "As when... so..." simile** and, if scope
   allows, a catalogue.
6. **Bound the length** to a coherent excerpt/canto and instruct ending on a
   completed movement, not a mid-sentence cutoff.
7. **Ban AI poeticism crutches** ("tapestry," "symphony," "delve," "testament") in
   the prompt.
8. Fold `prompt.system` art-direction (mythic palette, mood) into imagery and
   epithet choice. Output is plain text via the chat provider path.

## See Also
- `sonnet.md`, `haiku.md`, `limerick.md` (sibling fixed-form verse)
- `short-story.md`, `novel-chapter.md` (prose narrative craft — arc, POV)
- `../use-case/document-processing.md`
