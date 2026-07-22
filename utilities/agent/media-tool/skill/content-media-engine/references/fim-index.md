# FIM Library Cross-Reference Index

Maps each `text_format` supported by the media asset generation system to its corresponding FIM solution and use-case files in the bundled FIM library.

All paths are relative to this file's location (`skill/content-media-engine/references/`).

## Format-to-FIM Mapping

| text_format | Category | FIM Solution | FIM Use-Case | Default Extension |
|-------------|----------|-------------|--------------|-------------------|
| mermaid | diagram | `fim/solution/mermaid.md` | `fim/use-case/diagram-generation.md` | .mmd |
| plantuml | diagram | `fim/solution/plantuml.md` | `fim/use-case/diagram-generation.md` | .puml |
| graphviz | diagram | `fim/solution/graphviz.md` | `fim/use-case/diagram-generation.md` | .dot |
| drawio | diagram | `fim/solution/drawio-xml.md` | `fim/use-case/diagram-generation.md` | .drawio |
| svg | image | (multiple -- see design-systems use-case) | `fim/use-case/design-systems.md` | .svg |
| html | page | (inline CSS/JS -- see prototyping use-case) | `fim/use-case/prototyping.md` | .html |
| tsx | component | (React patterns -- see prototyping use-case) | `fim/use-case/prototyping.md` | .tsx |
| latex | document | `fim/solution/latex.md` | `fim/use-case/document-processing.md` | .tex |
| typst | document | `fim/solution/typst.md` | `fim/use-case/document-processing.md` | .typ |
| abc | music | `fim/solution/abcjs.md` | `fim/use-case/music-notation.md` | .abc |
| lilypond | music | `fim/solution/lilypond.md` | `fim/use-case/music-notation.md` | .ly |
| wavedrom | engineering | `fim/solution/wavedrom.md` | `fim/use-case/engineering-diagrams.md` | .json |
| katex | math | `fim/solution/katex.md` | `fim/use-case/mathematical-scientific.md` | .tex |

## Literature / Text Genre Mapping

These `text_format` values route to genre-craft solution files (rhetorical conventions,
structure, and constraints for a specific prose/verse/marketing/doc genre). Output is plain
text or markdown via a chat provider. The prep agent loads the matching file and shapes the
generation prompt to the genre's conventions.

| text_format | Category | FIM Solution | Default Extension |
|-------------|----------|-------------|-------------------|
| haiku | poetry | `fim/solution/haiku.md` | .txt |
| epic-poem | poetry | `fim/solution/epic-poem.md` | .txt |
| sonnet | poetry | `fim/solution/sonnet.md` | .txt |
| limerick | poetry | `fim/solution/limerick.md` | .txt |
| short-story | literary | `fim/solution/short-story.md` | .md |
| novel-chapter | literary | `fim/solution/novel-chapter.md` | .md |
| ad-copy | marketing | `fim/solution/ad-copy.md` | .txt |
| marketing-copy | marketing | `fim/solution/marketing-copy.md` | .md |
| press-release | marketing | `fim/solution/press-release.md` | .md |
| seo-article | marketing | `fim/solution/seo-article.md` | .md |
| email-copy | marketing | `fim/solution/email-copy.md` | .md |
| user-manual | instructional | `fim/solution/user-manual.md` | .md |
| getting-started | instructional | `fim/solution/getting-started.md` | .md |
| api-reference | instructional | `fim/solution/api-reference.md` | .md |
| technical-blog | instructional | `fim/solution/technical-blog.md` | .md |
| readme | instructional | `fim/solution/readme.md` | .md |
| ux-microcopy | ux | `fim/solution/ux-microcopy.md` | .txt |

## Provider / Generator Mapping

Binary-media `service` targets route to generator prompt-engineering files under
`fim/solution/providers/` (see `PROVIDER-INDEX` in that dir). Implemented: `gemini`→imagen,
`veo`, `grok-video`, `suno`, `elevenlabs`, `openai-tts`, `qwen-tts`. Forward-looking:
stable-diffusion, flux, midjourney, runway-gen3, sora, udio.

## Usage

When authoring a `.media.prompt` file for a given format, consult:

1. **FIM Solution** -- syntax reference, capabilities, and limitations of the format
2. **FIM Use-Case** -- patterns, best practices, and common configurations for the category
3. **Prompt Template** -- pre-built system prompt and example (see `prompt-templates/`)
