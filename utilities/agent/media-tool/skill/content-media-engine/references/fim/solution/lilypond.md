# LilyPond — Text-Based Music Engraving System

LilyPond is a batch music-engraving program that compiles a plain-text `.ly` source
file into publication-quality PDF, PNG, SVG, PostScript, and MIDI output. It is not a
GUI or a live-render library: you write notation in its domain-specific language, then
run the `lilypond` compiler. Output quality rivals hand-engraved scores, which makes it
the standard for academic publishing, complex classical scores, and algorithmic score
generation.

**Current Version**: 2.24.x (stable), 2.25.x (development)  **License**: GPLv3
**Runtime**: Native binary (C++/Scheme/Guile); no browser runtime — server-side or CLI only

## Official Resources & Documentation
- Official site: https://lilypond.org/
- Full manual (Notation Reference): https://lilypond.org/doc/latest/Documentation/notation/
- Learning Manual: https://lilypond.org/doc/latest/Documentation/learning/
- Internals Reference (grobs, contexts, engravers): https://lilypond.org/doc/latest/Documentation/internals/
- Snippet Repository (LSR): https://lsr.di.unimi.it/
- Source (GitLab): https://gitlab.com/lilypond/lilypond
- Online sandbox: https://hacklily.org/ , https://www.lilybin.com/

## Installation & Setup

### Native install
```bash
# macOS
brew install lilypond

# Debian/Ubuntu
sudo apt-get install lilypond

# Arch
sudo pacman -S lilypond

# Any OS: official self-contained binary from lilypond.org/download
```

### Compile a file
```bash
lilypond score.ly            # → score.pdf (+ score.midi if \midi block present)
lilypond --png score.ly      # PNG raster output
lilypond --svg score.ly      # SVG (one file per page)
lilypond -dbackend=svg -o out score.ly
lilypond -dresolution=300 --png score.ly   # 300 DPI raster
```

### Embedding in web workflows
LilyPond has no client-side runtime. Serve it via a compile service (queue a job, return
the rendered PDF/SVG), or precompile assets at build time. `lilypond-book` splices scores
into HTML/LaTeX/Texinfo documents.

## Core Syntax / Language Reference

A LilyPond file is a tree of **music expressions** placed inside top-level blocks. The
compiler routes music through **contexts** (Score → Staff → Voice) and **engravers** that
produce graphical objects ("grobs").

### File skeleton
```lilypond
\version "2.24.0"          % REQUIRED first line — declares source-language version

\header {                  % titling metadata (not musical)
  title = "Sonata in C"
  composer = "A. Composer"
  opus = "Op. 1"
}

\score {                   % binds music + output blocks together
  \new Staff \relative c' {
    \clef treble
    \key c \major
    \time 4/4
    c4 d e f | g1
  }
  \layout { }              % produce visual score
  \midi   { }              % also produce MIDI
}
```

### Pitches
Dutch note names `c d e f g a b`. Accidentals are suffixes: `is` = sharp, `es` = flat
(`cis` = C♯, `bes` = B♭, `fisis` = F𝄪). Octave marks: `'` up an octave, `,` down.
```lilypond
c'    % middle C region
cis'  % C sharp
bes   % B flat below
c''   % octave above
```

### Absolute vs relative octave
```lilypond
\relative c' { c d e f g }   % each note picks the octave nearest the previous
{ c' d' e' f' g' }           % absolute — every octave stated explicitly
```
`\relative` is the idiom for hand-written melodies; absolute is safer for machine
generation because it has no positional dependency.

### Durations
A number after the note name = reciprocal duration; a trailing `.` dots it. Duration is
**sticky** — it persists until changed.
```lilypond
c1    % whole note
c2    % half
c4    % quarter
c8    % eighth
c16   % sixteenth
c4.   % dotted quarter
c4..  % double-dotted
c2 c c4 c   % second/third notes inherit "2"; then "4"
```

### Rests, spacers, multi-measure rests
```lilypond
r4          % quarter rest
r2. r8      % dotted-half rest, eighth rest
s4          % invisible spacer rest (occupies time, prints nothing)
R1*4        % 4 bars of full-measure rest, collapsed to one symbol
```

### Chords, ties, slurs, beams
```lilypond
<c e g>4          % chord (simultaneous notes)
c4 ~ c            % tie (same pitch, joined duration)
c4( d e f)        % slur (phrase mark)
c8[ d e f]        % manual beam (auto-beaming is usually on)
c4\( d e\)        % phrasing slur (outer level)
```

### Bar lines, repeats, endings
```lilypond
\bar "|."                       % final bar line
\repeat volta 2 { c4 d e f }    % printed repeat (|: … :|)
\repeat volta 2 { c4 d e f }
\alternative { { g1 } { a1 } }  % 1st/2nd endings
\repeat unfold 4 { c4 }         % expand literally (also affects MIDI)
```

### Time, key, clef, tempo
```lilypond
\time 6/8
\key d \minor          % modes: \major \minor \dorian \mixolydian …
\clef bass             % treble, alto, tenor, bass, "treble_8", percussion
\tempo 4 = 120         % metronome mark
\tempo "Allegro" 4 = 120
\partial 4             % pickup / anacrusis of one quarter
```

### Dynamics, articulation, ornaments
```lilypond
c4\pp c\ff             % dynamics attach with backslash
c4\< d e f\!           % hairpin crescendo, terminated by \!
c4-. c-> c-^ c--       % staccato, accent, marcato, tenuto
c4\trill c\turn        % ornaments
c4\fermata
```

### Text markup
`\markup` is a mini-typesetting language for titles, rehearsal marks, fingerings, and
free text.
```lilypond
c4^\markup { \bold "cantabile" }
c4_\markup { \italic \small "pizz." }
\mark \markup { \box "A" }               % rehearsal mark
```

### Multiple voices on one staff
```lilypond
\new Staff <<
  \new Voice { \voiceOne c'2 d' }
  \new Voice { \voiceTwo g4 f e d }
>>
% shorthand: << { … } \\ { … } >>
```

### Lyrics
```lilypond
<<
  \new Voice = "mel" \relative c' { c4 d e f }
  \new Lyrics \lyricsto "mel" { These are the words }
>>
```

## Output & Score Structure (`\paper`, `\layout`, `\header`, `\midi`)

### `\header` — titling fields
`title`, `subtitle`, `composer`, `arranger`, `poet`, `opus`, `piece`, `tagline`,
`copyright`. Placed at top level (whole file) or inside a `\score`.

### `\paper` — page geometry (document-wide)
```lilypond
\paper {
  #(set-paper-size "a4")     % or "letter", "a3", …
  top-margin = 15\mm
  left-margin = 20\mm
  line-width = 170\mm
  indent = 0\mm              % first-system indent
  ragged-right = ##f         % justify last system to full width
  system-system-spacing.basic-distance = #12
}
```

### `\layout` — engraving rules (per-score)
```lilypond
\layout {
  \context {
    \Score
    \override SpacingSpanner.spacing-increment = #1.2
    \remove "Bar_number_engraver"
  }
}
```

### `\midi` — audio export
Add an empty `\midi { }` to any `\score` to emit a `.midi` file. `\tempo` marks and
`\dynamic` context settings shape playback. Use `\set Staff.midiInstrument = "violin"`
to choose a General MIDI voice.

## How-To (worked recipes)

### How to add color to notes and staff elements
Color is set by overriding the grob's `color` property. Use named colors or RGB.
```lilypond
\version "2.24.0"
\relative c' {
  \override NoteHead.color = #red
  \override Stem.color = #(rgb-color 0.2 0.4 0.9)
  \override Staff.TimeSignature.color = #(x11-color 'ForestGreen)
  c4 d
  \once \override NoteHead.color = #blue   % \once = just the next note
  e f
}
```
`\override` is permanent until reverted; `\once \override` affects only the next moment.
`\revert NoteHead.color` restores the default.

### How to generate a score algorithmically (absolute octaves)
For machine generation, emit absolute-octave notes so output never depends on note order.
```lilypond
\version "2.24.0"
\score {
  \new Staff {
    \key g \major \time 4/4
    g'8 a' b' c'' d'' e'' fis'' g'' |   % ascending G-major scale
    g''4 d'' b' g'
  }
  \layout { } \midi { }
}
```

### How to write a piano grand staff
```lilypond
\version "2.24.0"
\new PianoStaff <<
  \new Staff = "RH" { \clef treble  \relative c'' { c4 e g e | c1 } }
  \new Staff = "LH" { \clef bass    \relative c  { c4 g e g | c,1 } }
>>
```

### How to transpose a passage
`\transpose from to { music }` shifts everything by the interval `from → to`.
```lilypond
\version "2.24.0"
% concert pitch written up a major second for a B-flat instrument:
\transpose bes c' \relative c' { c4 d e f g1 }
```

### How to change the default note length globally
Set the base duration once; sticky durations flow from it.
```lilypond
\version "2.24.0"
\relative c' {
  c8 d e f g a b c   % all eighths — duration stated once, inherited
}
```

## Do's and Don'ts

### ✅ Do
- Start every file with `\version "2.24.0"` — the compiler uses it to auto-update syntax and to warn on mismatch.
- Use `\relative` for hand-written melody, absolute octaves for generated scores.
- Let auto-beaming and auto-accidentals do their job; only override at true exceptions.
- Add `\midi { }` alongside `\layout { }` when you need audio — one source, two outputs.
- Prefer `\once \override` for single-note tweaks so you don't have to `\revert`.

### ❌ Don't
- Don't forget the octave check drift in `\relative` — a wrong first octave shifts the whole line.
- Don't hard-code page coordinates for spacing; adjust `\paper`/`\layout` properties so LilyPond re-flows correctly.
- Don't expect real-time rendering — LilyPond is a batch compiler; a full page can take seconds.
- Don't confuse `\set` (context property, e.g. `midiInstrument`) with `\override` (grob property, e.g. `NoteHead.color`).
- Don't omit `\!` to close a hairpin — an unterminated `\<` runs to the end of the passage.

## Styling, Theming & Customization
- **Fonts**: LilyPond ships Emmentaler (music) and can use any installed text font via
  `\paper { #(define fonts …) }` or the simpler `fonts.roman` override.
- **Grob overrides**: nearly every visual object exposes properties — `NoteHead`, `Stem`,
  `Beam`, `Slur`, `TextScript`, `Accidental`, `BarLine`. Discover them in the Internals Reference.
- **Stylesheets**: put shared `\layout`/`\paper` blocks in an included `.ily` file and
  `\include "style.ily"` across scores.
- **Sizes**: `#(set-global-staff-size 18)` scales the entire score; `\magnifyStaff` scales one staff.
- **Custom markup**: define reusable markup commands with `#(define-markup-command …)` in Scheme.

## Advanced Features
- **Scheme/Guile scripting**: LilyPond embeds Guile — `#(…)` drops into Scheme for
  programmatic music, custom functions, and conditional engraving.
- **`lilypond-book`**: extract and typeset LilyPond snippets embedded in LaTeX/HTML/Texinfo.
- **Cue notes, ossia, figured bass, chord names, tablature** (`\new TabStaff`), Gregorian/
  mensural notation, and microtonal accidentals are all first-class.
- **`\tag` / `\keepWithTag`**: emit multiple versions (full score vs. individual parts) from one source.
- **MusicXML import**: `musicxml2ly score.musicxml` converts to `.ly` (lossy for complex layout).

## Common Pitfalls & Troubleshooting
- **"version mismatch"**: run `convert-ly -e file.ly` to upgrade old syntax automatically.
- **Blank/tiny output**: a missing `\layout { }` inside `\score` suppresses visual rendering when a `\midi` block is present.
- **Collisions/overlaps**: usually a spacing property; increase `line-width` or adjust `\override`s rather than moving things by hand.
- **Wrong octaves in `\relative`**: the reference pitch after `\relative` sets the whole line; verify it.
- **Slow compiles**: large orchestral scores are CPU-bound; cache rendered PDFs, don't recompile per request.
- **Encoding**: save `.ly` as UTF-8; non-ASCII lyrics need it.

## Integration Notes
- Server-side render service: enqueue `.ly`, shell out to `lilypond --svg`, cache result.
- CI/build asset pipeline: precompile scores to SVG/PNG at build time; ship static images to the browser.
- `lilypond-book` integrates into docs toolchains (Sphinx via raw HTML, LaTeX via `\begin{lilypond}`).

## Best For / Avoid For
`publication-quality`, `classical`, `orchestral`, `academic`, `algorithmic-generation`,
`archival`, `print` — choose LilyPond when engraving quality and fine control matter more
than interactivity.
Avoid for: real-time/browser rendering (use `vexflow` or `abcjs`), interactive editing
(use `osmd` + an editor, or `noteflight-api`), or quick web embeds where a compile step is
unacceptable.

## See Also
- [abcjs](abcjs.md) — lightweight text notation that renders live in the browser
- [vexflow](vexflow.md) — programmatic JS notation rendering
- [osmd](osmd.md) — render MusicXML in the browser
- [musicxml](musicxml.md) — interchange format; `musicxml2ly` imports it into LilyPond
- [mei](mei.md) — scholarly XML encoding
- Use case: [../use-case/music-notation.md](../use-case/music-notation.md)
