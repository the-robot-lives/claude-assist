// Neutral entry point for the org-scoped list/signup read API.
//
// The concrete implementation lives in `@/components/admin/admin-fetch` — it was
// first written for the admin console, but every endpoint it calls is an AUTHED
// ORG-SCOPED route (GET /organizations/:orgId/projects, .../lists,
// /lists/:id, /lists/:id/signups), gated by org membership + PBAC on the backend
// rather than by the admin flag. Org dashboard pages import from here so the
// "admin" naming never leaks into non-admin code paths.

export {
  AdminApiError as OrgApiError,
  adminListServices as listServices,
  adminListLists as listServiceLists,
  adminShowList as showList,
  adminListSignups as listSignups,
  adminFetchAllSignups as fetchAllSignups,
  optInMode,
  signupsToCsv,
  downloadCsv,
  collectAttributeKeys,
} from "@/components/admin/admin-fetch";

export type {
  ListKind,
  ListStatus,
  SignupStatus,
  AdminService as OrgService,
  AdminList as OrgList,
  AdminSignup as OrgSignup,
  ListSettings,
  SignupsPage,
} from "@/components/admin/admin-fetch";
