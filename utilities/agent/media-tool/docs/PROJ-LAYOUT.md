# Project Layout

```
media-tool/
├── src/                            # Rust source → [layout/src.md](layout/src.md)
│   ├── main.rs                     #   CLI entry point (clap, pipeline orchestration)
│   ├── schema.rs                   #   YAML prompt parsing and normalization
│   ├── pipeline.rs                 #   Generation pipeline (dry-run, execute, parallelism)
│   ├── dag.rs                      #   Dependency DAG resolution (Kahn's algorithm)
│   ├── attachments.rs              #   File attachment loading and base64 encoding
│   ├── output.rs                   #   Output file naming, format handling
│   ├── eval.rs                     #   Evaluation criteria and vision-based scoring
│   ├── refine.rs                   #   Interactive refinement loop
│   ├── prep.rs                     #   Prompt preparation/expansion via Groq LLM
│   ├── validate.rs                 #   Output validation (SVG lint + auto-fix loop)
│   ├── fim.rs                      #   FIM solution loader (skill references/fim library)
│   ├── ui.rs                       #   TUI (ratatui) and progress indicators
│   ├── providers/                  #   13 provider implementations → [layout/src.md](layout/src.md)
│   └── renderers/                  #   4 markup → visual renderers → [layout/src.md](layout/src.md)
├── bin/                            # Shell entry points
│   ├── generate-media-prompt       #   Bash wrapper (k8-lib, Python engine dispatch)
│   └── media-eval-port-forward     #   kubectl port-forward for in-cluster eval proxy
├── lib/                            # Legacy Python engine
│   └── media-prompt-engine.py      #   Single-file Python engine (stdlib + pyyaml)
├── demos/                          # Working .media.prompt examples by asset type
│   ├── image/                      #   Hero images, logos (Gemini Imagen)
│   ├── svg/                        #   SVG illustrations (chat + render)
│   ├── diagram/                    #   Mermaid, PlantUML diagrams
│   ├── html/                       #   HTML pages, React components
│   ├── video/                      #   Veo, Grok video clips
│   ├── music/                      #   Lo-fi beat (Suno)
│   ├── voice/                      #   OpenAI TTS, ElevenLabs, Qwen TTS
│   └── game/                       #   HTML5 game (Breakout clone)
├── skill/                          # Claude Code skill definitions
│   └── content-media-engine/       #   Content media engine skill
│       ├── SKILL.md                #     Skill entry point and triggers
│       ├── assets/                 #     Templates, trackers, example prompts, fim/ assets
│       └── references/             #     FIM library (fim/, fim-index.md), prompt-templates/, guides
├── project-management/             # Product management artifacts
│   ├── personas/                   #   8 user personas with index.yaml
│   └── user-stories/               #   100 user stories with index.yaml
├── docs/                           # Documentation
│   ├── PROJ-LAYOUT.md              #   This file
│   ├── PROJ-LAYOUT.summary.md      #   Quick-reference tree
│   ├── layout/                     #   Detailed breakdowns (src.md)
│   ├── providers.md                #   Provider implementation guide
│   └── quality-selection-and-eval.md  # Quality selection + eval system design
├── .gitignore                      #   Rust target/, Python __pycache__/, IDE files
├── Cargo.toml                      #   Rust package definition (bin + deps)
├── Cargo.lock                      #   Locked dependency versions
├── Makefile                        #   build, test, install, clean targets
├── HOW-TO.md                       #   Quick reference for writing .media.prompt files
├── LICENSE                         #   License file
└── README.md                       #   Full user documentation (schema, CLI, providers)
```

## Key Files Requiring Setup

| File | Action |
|------|--------|
| API keys | Set `GEMINI_API_KEY`, `SUNO_API_KEY`, `OPENAI_API_KEY`, etc. in `.envrc` or environment |
| `make install` | Builds Rust binary and installs to `~/.local/bin/generate-media-prompt` |

## Generation Details

- **demos/.genai.\*** directories contain cached generation outputs (timestamped); these are working artifacts, not source
- **demo \*.media.prompt files** are the actual prompt definitions — run any with `generate-media-prompt <path>`
