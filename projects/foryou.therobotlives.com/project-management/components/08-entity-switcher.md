# 08: EntitySwitcher (Org / Service)

| Field | Value |
|-------|-------|
| ID | CMP-08 |
| Category | Navigation & Layout |
| Used In | SCR-02, SCR-05, SCR-14 |

## Description
A dropdown switcher for the active Organization or Service, including a "+ New"
entry. One component parameterized by entity type; drives cross-context
navigation.

## Size Variants

| Variant | Use Case |
|---------|---------|
| Org | Switch active organization (+ New org) |
| Service | Switch active Service (+ New Service) |

## Props / Configuration
- `entityType` — org | service
- `items` — array — available entities
- `activeId` — currently selected
- `onSelect` — switch handler
- `onCreateNew` — opens the create flow

## Interactions
- Open list, select to switch (persists selection); "+ New" opens create flow
- Keyboard navigable menu
