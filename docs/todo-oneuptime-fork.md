# TODO: Fork and Patch OneUptime

## Issue: ClickHouse Migration Startup Order Bug

OneUptime's startup creates materialized views (MetricItemAggMV1m_mv,
MetricItemAggMV1mByHostV2_mv, MetricBaselineHourly_mv) BEFORE running
database migrations. When a migration needs to ALTER a column that those
views reference, ClickHouse rejects it with error 524
(ALTER_OF_COLUMN_IS_FORBIDDEN).

Affected migration: `ChangeMetricColumnTypeToDecimal` — changes the
`value` column from `Float64` to `Decimal128(5)`. The views reference
`value` via `coalesce(value, sum, 0)`, blocking the ALTER.

Additionally, the migration only changes the `value` column but the
materialized view SELECT expressions use `coalesce(value, sum, 0)` which
mixes types when `sum`/`min`/`max` remain as `Float64`. ClickHouse
throws error 386 (NO_COMMON_TYPE) when trying to create the views after
the partial migration.

### Root Cause

In the OneUptime app startup sequence:
1. Tables are created/verified
2. Materialized views are created if missing
3. Database migrations run (including column type changes)

Step 2 happens before step 3, so any migration that alters a column
referenced by a materialized view will always fail.

### Proposed Fix (for fork)

1. Run migrations BEFORE creating materialized views, OR
2. Have the migration code drop dependent views before altering columns
   and recreate them after, OR
3. Change `ChangeMetricColumnTypeToDecimal` to also convert `sum`, `min`,
   `max` columns to `Decimal128(5)` (not just `value`)

### Workaround Applied (2026-06-14)

Manually ran the migration via ClickHouse HTTP API:
- Dropped materialized views and their target tables
- ALTER TABLE MetricItemV3 MODIFY COLUMN value/sum/min/max to
  Nullable(Decimal128(5))
- Let the app recreate the views on next startup

### Other Notes

- No existing upstream GitHub issue found for this problem
- Upstream repo: https://github.com/OneUptime/oneuptime
- We run `oneuptime/app:release` image
- ClickHouse version: 25.5.6 (shared infra-clickhouse instance)
