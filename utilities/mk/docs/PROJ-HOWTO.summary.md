# PROJ-HOWTO — Summary

Task list for `utilities/mk`. Full guides in [PROJ-HOWTO.md](PROJ-HOWTO.md).

- **Wire a new Makefile group into the subdir-fan-out tree** — make a new group of child projects buildable/testable via `make build`/`test`/etc. from its parent.
- **Add a child project to an existing group** — make a new subproject participate in the existing fan-out without editing `subdirs.mk`.
- **Check the Makefile tree is consistent** — catch drift between on-disk Makefiles and declared `SUBDIRS` before it silently breaks `make install-utilities`.
- **Fan out a custom target (not build/compile/test/install/clean)** — dispatch a project-specific target like `lint` across a group's children using the same skip-if-absent logic.
- **Diagnose a child that stopped showing up in a fan-out run** — tell a genuine opt-out apart from a malformed child `Makefile` silently hiding as a skip.
- **Understand why `make build` ran `compile` instead** — explains the intentional `build`→`compile` fallback so it doesn't read as a bug.
