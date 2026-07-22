# Components

Extracted from the 22 screens in `../screens/`. Prioritizes components that appear
in 2+ screens, have complex interaction patterns, or have meaningful variants.

## Components by Category

| Category | Components |
|----------|-----------|
| Input & Forms | CMP-01 FormField, CMP-02 DynamicForm, CMP-03 Button, CMP-15 SearchFilterBar, CMP-16 ExportButton, CMP-19 HoneypotField, CMP-20 BrandingEditor |
| Feedback & Indicators | CMP-04 InlineAlert, CMP-07 EmptyState, CMP-17 TokenResultPanel |
| Tables & Lists | CMP-05 DataTable |
| Data Display | CMP-06 StatTile, CMP-10 StatusBadge |
| Navigation & Layout | CMP-08 EntitySwitcher, CMP-11 AppShell |
| Cards & Tiles | CMP-09 SummaryCard |
| Modals & Overlays | CMP-18 ConfirmDialog, CMP-22 DetailPanel |
| Domain-Specific | CMP-12 AttributeEditor, CMP-13 PreferenceControls, CMP-14 SubscriptionList, CMP-21 MigrationStatusTable |

## Full Index

| ID | Component | Used-in count | Screens |
|----|-----------|---------------|---------|
| CMP-01 | FormField | 10 | SCR-01, SCR-03, SCR-04, SCR-07, SCR-08, SCR-10, SCR-11, SCR-12, SCR-15, SCR-21 |
| CMP-02 | DynamicForm | 3 | SCR-10, SCR-11, SCR-12 |
| CMP-03 | Button | 11 | SCR-01, SCR-02, SCR-03, SCR-05, SCR-06, SCR-07, SCR-08, SCR-13, SCR-14, SCR-16, SCR-22 |
| CMP-04 | InlineAlert | 8 | SCR-01, SCR-04, SCR-07, SCR-11, SCR-12, SCR-13, SCR-15, SCR-21 |
| CMP-05 | DataTable | 5 | SCR-04, SCR-18, SCR-19, SCR-20, SCR-22 |
| CMP-06 | StatTile | 3 | SCR-06, SCR-17, SCR-18 |
| CMP-07 | EmptyState | 5 | SCR-02, SCR-05, SCR-06, SCR-14, SCR-16 |
| CMP-08 | EntitySwitcher | 3 | SCR-02, SCR-05, SCR-14 |
| CMP-09 | SummaryCard | 3 | SCR-05, SCR-06, SCR-08 |
| CMP-10 | StatusBadge | 4 | SCR-04, SCR-18, SCR-19, SCR-22 |
| CMP-11 | AppShell | 2 | SCR-02, SCR-17 |
| CMP-12 | AttributeEditor | 1 | SCR-09 |
| CMP-13 | PreferenceControls | 2 | SCR-08, SCR-15 |
| CMP-14 | SubscriptionList | 1 | SCR-14 |
| CMP-15 | SearchFilterBar | 2 | SCR-19, SCR-20 |
| CMP-16 | ExportButton | 2 | SCR-16, SCR-19 |
| CMP-17 | TokenResultPanel | 1 | SCR-13 |
| CMP-18 | ConfirmDialog | 2 | SCR-16, SCR-22 |
| CMP-19 | HoneypotField | 3 | SCR-11, SCR-12, SCR-21 |
| CMP-20 | BrandingEditor | 1 | SCR-07 |
| CMP-21 | MigrationStatusTable | 1 | SCR-22 |
| CMP-22 | DetailPanel | 2 | SCR-19, SCR-20 |

Single-screen components (CMP-12, CMP-14, CMP-17, CMP-20, CMP-21) are retained
because they are complex, domain-specific, or high-value composites.

## Total: 22 components
