'use client';

import { useOrg } from '@/context/org';

// ⟦𓂁𓎛𓊧𓍹⟧ OrgSwitcher :: auto-generated pointer for public function OrgSwitcher
export function OrgSwitcher() {
  const { currentOrg, organizations, switchOrg } = useOrg();

  if (organizations.length <= 1) return null;

  return (
    <select
      value={currentOrg?.id || ''}
      onChange={(e) => switchOrg(e.target.value)}
      className="org-switcher"
    >
      {organizations.map((org) => (
        <option key={org.id} value={org.id}>
          {org.name}
        </option>
      ))}
    </select>
  );
}
