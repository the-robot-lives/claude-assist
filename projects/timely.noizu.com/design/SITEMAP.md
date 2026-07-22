# Timely Sitemap

## Route Map

| Route | Screen | Purpose |
|-------|--------|---------|
| `/` | SCR-10 Dashboard | Overview of today, exceptions, team/project health, and review queues. |
| `/onboarding` | SCR-01 Workspace Setup | First-run workspace, agent, permissions, policy, and project setup. |
| `/invite` | SCR-02 Team Invitation And Consent | Invitation acceptance and team consent review. |
| `/agent` | SCR-03 Desktop Agent Status | Capture health, permissions, pause/resume, and sync status. |
| `/track` | SCR-04 Live Task Switcher | Fast current-task switching and overlapping task capture. |
| `/timeline/[date]` | SCR-05 Daily Timeline | Main review and correction surface. |
| `/timeline/[date]/idle` | SCR-09 Idle Gap Review Queue | Batch review for unresolved idle and resume events. |
| `/summary/week/[week]` | SCR-11 Weekly Summary | Weekly focus, billing, idle, and interruption analytics. |
| `/team` | SCR-12 Team Utilization | Privacy-aware team utilization and project burn. |
| `/approvals` | SCR-13 Timesheet Approval | Manager review and approval workflow. |
| `/reports` | SCR-14 Report Builder | Client-ready reporting and exports. |
| `/reports/history` | SCR-15 Export History | Export archive, invoice status, and webhook delivery. |
| `/work` | SCR-16 Clients Projects Tasks | Client, project, task, rate, and archive management. |
| `/settings/privacy` | SCR-17 Privacy And Capture Policies | Screenshot intervals, retention, exclusions, and redaction preview. |
| `/settings/roles` | SCR-18 Roles Permissions Audit | Roles, permissions, deletion requests, and audit log. |
| `/settings/integrations` | SCR-19 Integrations Hub | Calendar, GitHub, issue tracker, Slack, API, MCP, and webhooks. |
| `/settings/accessibility` | SCR-20 Accessibility Preferences | Keyboard, theme, motion, contrast, and locale preferences. |

## Overlays

- Interval Detail Drawer - opened from `/timeline/[date]`.
- Screenshot Detail And Redaction - opened from timeline, gallery, or reports.
- Idle And Resumption Prompt - opened by desktop return events or unresolved gap review.
- Sync Conflict Resolver - opened from agent status or integrations.

## Navigation Model

Primary navigation: Dashboard, Timeline, Reports, Work, Team, Settings.

Secondary navigation inside Settings: Privacy, Roles, Integrations, Accessibility.

Desktop agent navigation should stay minimal: current task, capture state, pause/resume, last screenshot, unresolved prompt count, and open web dashboard.
