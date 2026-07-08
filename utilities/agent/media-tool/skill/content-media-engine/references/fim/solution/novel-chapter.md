# Novel Chapter — a propulsive unit of a longer story

A novel chapter is a structural unit of a larger narrative: a bounded stretch of
story that carries its own goal, conflict, and turn while advancing the book's
throughline and ending on a hook that pulls the reader forward. Its craft differs
from the short story's: a chapter does not need a *complete* arc — it needs a
purpose, momentum, and a reason to keep reading. Good chapters open with a clear
scene goal, escalate through conflict, and close on a disaster, question, or
reversal (a page-turn hook); bad chapters meander with no goal, resolve too
neatly (killing momentum), drift POV, or dump backstory and exposition. Readers
expect continuity of POV and voice, forward drive, and a cliff to lean over at
the chapter break.

**Output form**: prose (markdown paragraphs; scene breaks allowed)  **Typical length**: ~2,500–4,000 words
**Routed via**: `text_format: novel-chapter` (chat-type generation)

## Genre Conventions & Structure

**Scene-and-Sequel (Dwight Swann / Jack Bickham model)** — the engine of chapter
pacing:

- **Scene** (proactive unit) = **Goal → Conflict → Disaster**
  - *Goal*: what the POV character wants in this scene (concrete, immediate).
  - *Conflict*: the obstacles/opposition that thwart the goal.
  - *Disaster*: the scene ends worse than it started — a setback, a "yes, but,"
    or a "no, and furthermore." This is what generates momentum.
- **Sequel** (reactive unit) = **Reaction → Dilemma → Decision**
  - *Reaction*: the emotional fallout of the disaster.
  - *Dilemma*: the character weighs bad options.
  - *Decision*: they choose a new goal → which launches the next scene.

A chapter is typically one scene, one sequel, or a scene+sequel pair — sometimes
two short scenes. Not every chapter follows this rigidly, but the **goal /
conflict / disaster** spine is what keeps chapters from going slack.

**Chapter-level conventions:**

- **Open with a hook and orient fast** — re-establish POV character, place, and
  time in the first lines (especially after a POV switch), then get moving.
- **A scene goal within the first page** — the reader should know what the POV
  character is trying to do.
- **Escalating conflict** — the middle raises stakes or complications.
- **End on a hook** — a disaster, revelation, question, or reversal that makes
  stopping feel intolerable. The chapter break is a *tension* device.
- **POV consistency** — one POV character per scene; if the book alternates POV,
  switch only at chapter/scene breaks, never mid-scene.
- **Advance the throughline** — the chapter must move the book's central plot
  and/or deepen character; a chapter that changes nothing is cuttable.
- **Continuity** — honor what prior chapters established (names, facts, timeline,
  emotional state).

## Hard Constraints

1. **One consistent POV and tense** for each scene (and typically the whole
   chapter) — no head-hopping, no drift between "I"/"she" or past/present.
2. **A clear scene goal** established early and a **disaster/hook** at the chapter's
   end — the chapter must not resolve into a comfortable full stop.
3. **Forward movement** — the chapter changes the story state (plot advances or a
   character shifts); it is not a static interlude (unless the brief calls for one).
4. **Length in the ~2,500–4,000-word band** (respect any bound in the brief;
   chapters vary, but this is the working target).
5. **Continuity with supplied context** — if the brief/`prompt.system` gives prior
   events, character names, or a synopsis, the chapter must not contradict them.
6. **Scene-level dramatization** — the important beats are lived scenes, not summary.

## How-To (worked recipes)

### How to open a chapter that grabs and orients
Lead with a line of action, tension, or a vivid concrete image, then anchor
who/where/when within a sentence or two. After a POV switch, name the POV
character early so the reader re-centers. Bad: three paragraphs recapping the last
chapter. Good: "The ransom note was still warm from the printer when Devi's phone
rang." — hook + POV + implied stakes, immediately.

### How to give the scene a goal and escalate it
State (or imply) what the POV character wants *now*, then throw obstacles that make
it harder. Use "yes, but" / "no, and" outcomes: they get partway, but a new
complication lands. Each beat should cost something. Track the goal so the reader
always knows what's at stake in this scene.

### How to end on a page-turn hook
Close on the disaster or a destabilizing new element: a reversal ("The man in the
photo was her father"), a threat, an unanswered question, a decision with
consequences, or a cliff-edge mid-action. Cut a beat *earlier* than feels safe —
end on the spike, not the settle. Don't wrap the chapter in a neat bow; that
signals "safe to stop."

### How to hold POV and avoid head-hopping
Filter every perception, thought, and judgment through the one POV character for
the scene. We can know only what they observe or infer. If you need another
character's interior, that's a different scene/chapter — switch only at a break.
Watch for accidental slips ("she had no idea he was lying" — but the POV *is* her,
so she can't narrate his lie).

### How to weave backstory without stalling
Deliver backstory in small, motivated doses *inside* forward motion — a memory
triggered by a present object, one line of context where it's needed — never a
front-loaded infodump. If the reader doesn't need it yet, cut it. Momentum first.

### How to use a sequel to reset before the next scene
After a big disaster, a short sequel (reaction → dilemma → decision) lets the
character (and reader) breathe and reorient, then commits to a new goal that
launches the next chapter. This rhythm — spike, breathe, spike — is what sustains
a novel's pace.

## Do's and Don'ts

### ✅ Do
- Open with a hook and orient POV/place/time fast.
- Give the scene a concrete goal and escalate the conflict.
- End on a disaster/reversal/question — a page-turn hook.
- Hold one POV per scene; switch only at breaks.
- Advance the book's throughline; make the chapter matter.
- Dose backstory in motion.

### ❌ Don't
- **Don't recap the previous chapter** at length to open — trust the reader.
- **Don't head-hop** or drift POV/tense mid-scene.
- **Don't resolve everything** and end on a calm full stop — that kills momentum.
- **Don't infodump** backstory or worldbuilding in a block.
- **Don't write a goalless, eventless chapter** where nothing changes.
- **Don't contradict established continuity** (names, timeline, facts, emotions).
- **Don't summarize the chapter's climactic beat** — dramatize it.

## Tone, Voice & Register

Governed by the book's established voice and the POV character's filter — a chapter
must sound like the rest of the novel. Close-third or first-person narration colors
diction, observation, and what gets noticed. Register can be literary, commercial,
genre-specific (thriller = lean and fast; literary = more interior); match the
brief and prior chapters. Active voice and strong verbs; vary sentence rhythm for
pacing (clipped for tension, longer for reflection). Dialogue in the characters'
distinct voices, with subtext.

## Platform / Placement Constraints

Prose in paragraphs. May open with a chapter heading only if the brief wants one
("Chapter 7" or a titled chapter) — otherwise emit the prose. Scene breaks within
the chapter marked by a blank line and "* * *" or "#". Dialogue on a new paragraph
per speaker. Respect the word bound. Because a chapter is a *unit of a larger
work*, it should end at the hook, not force artificial closure — a deliberately
open ending is correct here (unlike a short story).

## Common Pitfalls & Anti-patterns (incl. AI-tells)

- **No scene goal / no disaster.** The dominant structural failure: a chapter where
  people talk and wander but nothing is wanted and nothing goes wrong. Momentum
  dies. Impose Goal → Conflict → Disaster.
- **Neat resolution at the chapter end** — everything settled, tension released.
  End on the hook instead.
- **Opening recap dumps** — re-narrating the last chapter's events. Start moving.
- **Head-hopping** — slipping into other characters' thoughts within a scene.
- **Infodump / worldbuilding block** — paragraphs of history or lore halting the
  story. Weave it in motion.
- **Telling emotion** — "she felt terrified" instead of the bodily/behavioral
  evidence.
- **AI diction tells**: "delve," "a testament to," "navigate the complexities,"
  "a tapestry of," "in that moment," "little did she know," "sent a chill down her
  spine," "the tension was palpable," "a symphony of emotions." Ban these.
- **Em-dash overuse and adverb-stuffed dialogue tags** ("she whispered softly,
  fearfully").
- **Flat, even pacing** — no spike/breathe rhythm; every scene the same intensity.
- **Chapter that could be deleted** with no effect on the book — it must change
  something.
- **Contradicting continuity** — an LLM invents a detail that clashes with supplied
  context. Anchor to the given facts.

## Prep-Agent Notes (media-tool specific)

From the raw creative brief / `prompt.system`:
1. **Capture continuity context** — POV character, tense, prior events, character
   names, the book's tone, where this chapter falls — and put it in the generation
   prompt as binding facts to honor.
2. **Fix the POV and tense** for the chapter and forbid head-hopping explicitly.
3. **Define the scene spine**: the POV character's goal for this chapter, the
   conflict/opposition, and the ending disaster/hook. State all three in the prompt.
4. **State the target length** (word band) and the register (matching the book).
5. **Require a page-turn ending** (disaster/reversal/question) — forbid neat
   closure and forbid opening recaps.
6. **Instruct "show, don't tell," dose backstory in motion,** and list the
   AI-diction bans.
7. Fold `prompt.system` art-direction (genre, mood, setting) into voice, pacing,
   and sensory texture consistent with the larger work.
8. Output is prose (markdown paragraphs) via the chat provider path.

## See Also
- `short-story.md` (complete-arc contrast — chapters are units, not whole stories)
- `epic-poem.md` (long-form verse narrative)
- `../use-case/document-processing.md`
