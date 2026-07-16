# KB Stat Tile

| Field | Value |
|-------|-------|
| **ID** | `kb-stat-tile` |
| **Category** | Data Display |
| **Used In** | 10-Learning Plan Dashboard, 14-KB Maintenance Console, 17-Cloud Sync & Account, 18-Team Lead Dashboard |

## Description

A single at-a-glance metric — article count, deck size, topic coverage, growth over time, or sync status — reused from the personal KB Maintenance Console through to the team dashboard, where the same shape aggregates or breaks out per member.

## Size Variants

| Variant | Description |
|---------|-------------|
| **Inline** | `247 articles` |
| **Compact** | Metric plus trend arrow/delta since last week |
| **Expanded** | Sparkline/growth chart over time |

## Props / Configuration

- `label`, `value`, `delta`
- `trend` — array for the expanded sparkline
- `scope` — self \| team-member \| team-aggregate

## Interactions

- Selecting a tile drills into the relevant console (e.g. article count opens KB Browse & Search).
