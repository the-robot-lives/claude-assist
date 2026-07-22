# utilities/osx — FAQ Summary

Question index only — see [PROJ-FAQ.md](PROJ-FAQ.md) for full answers. This is a
grouping directory; child-internal FAQs are indexed at the bottom.

## Motivation
- Why does this directory exist instead of just putting fstab and queue-populator straight under utilities/?
- Why is the fan-out just a Makefile instead of a real build tool or task runner?

## Fit
- When should I use the group Makefile instead of just cd-ing into the child?
- Is this the right place to look if I'm not on macOS?

## Comparison
- How does fstab relate to queue-populator — do they interact?
- Why isn't there a group-level config file or shared install script?

## Caveats
- Does `make install` at the group root need root/sudo?

## Child FAQ Indexes
- **fstab**: [PROJ-FAQ.summary.md](../fstab/docs/PROJ-FAQ.summary.md)
- **queue-populator**: [PROJ-FAQ.summary.md](../queue-populator/docs/PROJ-FAQ.summary.md)
