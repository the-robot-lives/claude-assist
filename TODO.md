Todo
=====

- [ ] More advanced link mechanism to point to distant siblings, ancestors etc.
  - [ ] A Graph Root object builds a full node tree going into nested children. 432 -> [nodea, nodeb, nodec, 432]
    - [ ] we can use a patch builder that walks across nodes recursively
  - [ ] Anchored link support $uuid/path
  - [ ] scoped handles? (local_handle, tag, ...)
- [ ] document directive process
  - [ ] concrete, dynamic, etc.
- [ ] basic implementation or process_nodes (just trace path and set as an artifact) Runtime position?