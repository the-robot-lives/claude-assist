# How to: import existing AWS infrastructure via Terraformer

**Goal:** bring AWS resources created outside Terraform under management, without
re-creating them.
**Prereqs:** `terraform`, `aws` CLI with a profile that has the Terraformer import IAM
policy (see *grant the Terraformer import user its IAM permissions* in PROJ-HOWTO.md);
`infra-init` installed.

1. Confirm tooling and config are healthy first:
   ```bash
   infra-init doctor
   ```
2. Run the batch import — already-imported resource groups are skipped automatically:
   ```bash
   infra-init import
   ```
3. If a group needs re-importing (e.g. after fixing a bad attribute), force it:
   ```bash
   infra-init import --force
   ```
4. Clean up known-bad Terraformer attributes and spot-check against the live AWS state:
   ```bash
   infra-init cleanup
   ```
5. If the imported state used a legacy Terraformer provider, migrate it to modern TF:
   ```bash
   infra-init state-upgrade
   ```

**Verify:** `terraform plan` against the imported modules shows no unexpected diffs (a
clean `no changes` or only the changes you intended).
**Gotchas:**
- Import failing with permission errors → the `terraformer-import` AWS user is missing
  actions; run `add-import-permissions` to sync its policy, then retry.
- Re-running `infra-init import` without `--force` silently skips groups it thinks are
  already imported — use `--force` when you know the on-disk state is stale or partial.
- All real logic here lives in k8-lib `cmd_*` functions; `infra-init` itself is a thin
  dispatcher, so unexpected behavior is usually a k8-lib issue, not this script.
