# FAQ deep-dive: Terraformer import

### Why use Terraformer import (`infra-init import`) instead of hand-writing Terraform resource blocks for existing AWS infra?

Because hand-writing `resource` blocks for infra that already exists means re-deriving
every attribute (IDs, ARNs, tags, wiring) by hand from the AWS console/CLI, and a single
mistyped attribute either fails to import or — worse — silently plans to recreate the
resource on the next `apply`. Terraformer reads the live AWS API and generates both the
HCL and the matching state, so the starting point is "what's actually there," not "what I
remember or reconstructed." The trade-off: generated HCL is verbose and un-idiomatic
compared to hand-written modules, and known-bad Terraformer attributes need the
`infra-init cleanup` pass before the code is trustworthy — this is a bootstrap step for
already-created resources, not a substitute for hand-authoring new infra going forward.

→ *See [PROJ-HOWTO.md#how-to-import-existing-aws-infrastructure-via-terraformer](../PROJ-HOWTO.md#how-to-import-existing-aws-infrastructure-via-terraformer).*

### Why does the import flow need its own IAM user and permissions script (`add-import-permissions`) instead of using my own AWS credentials?

Because Terraformer's read/describe calls across many AWS services require a broad,
specific permission set that most personal/dev credentials don't carry and shouldn't be
widened to carry — granting it to a dedicated `terraformer-import` user keeps that
blast radius scoped to one purpose-built principal instead of permanently widening
whichever human or CI credential happens to run the import. `add-import-permissions`
exists specifically to keep that user's policy in sync with the canonical JSON checked
into the repo, so the grant is reviewable in a diff rather than clicked together once in
the AWS console and forgotten. The cost: one extra setup step (and IAM profile) before
your first import, versus just running it under your existing creds.

→ *See [PROJ-HOWTO.md#how-to-grant-the-terraformer-import-user-its-iam-permissions](../PROJ-HOWTO.md#how-to-grant-the-terraformer-import-user-its-iam-permissions).*

### Why is there a separate `infra-init state-upgrade` step — isn't Terraformer's output already usable Terraform state?

Not always — Terraformer has historically shipped a legacy-provider state format for some
resource types, which newer Terraform/OpenTofu provider versions won't read cleanly.
`state-upgrade` migrates that legacy state to the modern schema so `terraform plan`
against imported modules doesn't immediately show spurious diffs or provider errors. Only
run it when `infra-init cleanup`/`terraform plan` reveals legacy-format symptoms — running
it against already-modern state is a wasted step, not a harmful one.
