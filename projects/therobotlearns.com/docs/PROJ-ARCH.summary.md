# Project Architecture — Summary

**TRL-KB** is a cloud knowledge and learning application with a local Claude Code workspace agent. The cloud app is primary; the CLI bootstraps `~/.config/the-robot-learns-kb/` for offline/dev capture, artifact generation, and sync.

**Components**: CLI launcher (Node.js), template system (copied on first run), agent brain (CLAUDE.md), 5 sub-agents (doc-writer, flashcard-gen, topic-expander, quiz-gen, grader), 6 slash commands, React quiz SPA, terminal quiz CLI, 9 YAML schemas.

**Data**: All user data is flat YAML/Markdown files — knowledge articles, flashcard decks (SM-2), quizzes with score history, simulations, profiles, and session logs. Indexed via YAML index files, no database.

**Agent model**: Claude Code orchestrates; slash commands dispatch to specialized sub-agents (Sonnet for writing/grading, Haiku for generation/expansion). Profiles calibrate response depth to user expertise.

**Quiz runners**: Two consumers of the same quiz YAML format — a React SPA (single HTML build) and a terminal CLI (@inquirer/prompts). Both pre-built and shipped in the npm package.

**Key decisions**: cloud app as the primary product surface, Claude Code as local workspace runtime, human-readable sync formats, expertise-calibrated responses, SM-2 spaced repetition, dual quiz distribution.
