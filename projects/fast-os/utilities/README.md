# fast-os host utilities (macOS + Linux)

Tools for working with fast-os artifacts from a macOS or Linux host, without a
kernel driver.

## `fastfs`

Portable wrapper around the fastfs userspace tool (`../fastfs/`). Builds the
binary on first use, then forwards arguments to it. Works on macOS and Linux.

```bash
# make it convenient
export PATH="$PWD:$PATH"        # or: ln -s "$PWD/fastfs" ~/.local/bin/fastfs

# create and populate a fastfs image
fastfs mkfs ~/data.fastfs
fastfs import ~/data.fastfs ~/Documents /docs      # copy a host tree in
fastfs ls ~/data.fastfs /docs
fastfs policy ~/data.fastfs /docs mirror:2         # per-directory redundancy
fastfs tag add ~/data.fastfs /docs/report.pdf important
fastfs find-tag ~/data.fastfs important
fastfs snapshot ~/data.fastfs /docs before-edit    # per-folder history
fastfs history ~/data.fastfs /docs
fastfs scrub ~/data.fastfs                          # verify + self-heal replicas
fastfs export ~/data.fastfs /docs ~/docs-out        # copy back out to the host

# LLM / MCP tooling surface
fastfs mcp list
fastfs mcp schema
fastfs mcp call ~/data.fastfs fastfs.find_tag tag=important
```

`import`/`export` are the practical bridge today: they copy trees between the
host filesystem and a fastfs image. A FUSE mount (`fastfs-mount`, so the image
appears as a normal folder in Finder / on a Linux mountpoint) is the planned
next step — it needs macFUSE / libfuse bindings and is tracked in
[`../docs/fastfs-design.md`](../docs/fastfs-design.md).
