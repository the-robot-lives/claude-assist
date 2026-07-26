'use client';

import { useOrg } from '@/context/org';

export function OrgSwitcher() {
  const { currentOrg, organizations, switchOrg } = useOrg();

  if (organizations.length <= 1) return null;

  // Hand-styled rather than the shared `Select`: that primitive is `w-full`, and
  // this control sits inline in the top bar where it must size to its content.
  // The old `org-switcher` class had no rule anywhere — this rendered raw.
  return (
    <select
      value={currentOrg?.id || ''}
      onChange={(e) => switchOrg(e.target.value)}
      className="org-switcher cursor-pointer rounded-card border border-line2 bg-ground px-2.5 py-1 text-[12px] text-ink transition-colors hover:border-faint focus:border-acc focus:outline-none focus:ring-1 focus:ring-acc-line"
    >
      {organizations.map((org) => (
        <option key={org.id} value={org.id}>
          {org.name}
        </option>
      ))}
    </select>
  );
}
