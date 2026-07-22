// FE role-rank helper — affordance-gating LOGIC behind per-row RBAC visibility.
// Ranks mirror a typical BE @role_ranks: owner > admin > lead > member > viewer —
// LOWER number = HIGHER privilege. Tolerates the legacy org-member vocabulary
// (editor == member) so legacy role values and the RBAC ctx.effectiveRole compare
// on ONE scale.
//
// INVARIANT: this gates affordance VISIBILITY/keyboard-reachability ONLY — never
// enforcement. The server guard is the sole deny-closed boundary; a forged client
// that un-hides an action still 403s. Unknown roles rank 99 (deny-closed).

export const ROLE_RANK: Record<string, number> = {
  owner: 0,
  admin: 1,
  lead: 2,
  member: 3,
  editor: 3, // legacy alias for member
  viewer: 4,
};

/** Rank of a role; unknown/absent ranks 99 (deny-closed). */
export function roleRank(role?: string | null): number {
  return role != null && role in ROLE_RANK ? ROLE_RANK[role] : 99;
}

/** True when `role` is at least `min` privilege (rank <= min's rank). */
export function atLeast(role: string | undefined | null, min: string): boolean {
  return roleRank(role) <= roleRank(min);
}

/** True when `caller` strictly outranks `target` (higher privilege). */
export function outranks(caller?: string | null, target?: string | null): boolean {
  return roleRank(caller) < roleRank(target);
}
