# quick-gist — How-To Summary

Task list only — see [PROJ-HOWTO.md](PROJ-HOWTO.md) for full steps.

- **Install and verify quick-gist works** — get it on `$PATH` and confirm it can talk to GitHub.
- **Create a gist from specific files** — turn one or more files into a gist without leaving the shell.
- **Pick files interactively with fzf** — browse and multi-select files to gist without typing paths.
- **Create a gist from stdin** — pipe command output or clipboard content straight into a gist.
- **Add files to an existing gist** — append more files to a gist you already created.
- **Control gist visibility (secret vs public)** — decide whether a gist is unlisted or publicly listed; default is secret.
- **Use a specific GitHub account without changing your global gh auth** — create a gist as a different stored account, process-local only.
- **Gist a directory of large or many files without one giant upload failing silently** — automatic per-file incremental upload plus size-based chunking. *(→ [howto/large-files-and-chunking.md](howto/large-files-and-chunking.md))*
- **List your recent gists** — find a gist ID to add files to, or check what you've created recently.
