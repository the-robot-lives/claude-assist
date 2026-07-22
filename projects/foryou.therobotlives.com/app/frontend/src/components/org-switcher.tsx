'use client';

import { useOrg } from '@/context/org';
import { useRouter } from 'next/navigation';

const CREATE_ORG_VALUE = '__create_org__';

export function OrgSwitcher() {
  const { currentOrg, organizations, switchOrg } = useOrg();
  const router = useRouter();

  if (organizations.length <= 1) return null;

  return (
    <select
      value={currentOrg?.id || ''}
      onChange={(e) => {
        if (e.target.value === CREATE_ORG_VALUE) {
          router.push('/app/orgs/new');
          return;
        }
        switchOrg(e.target.value);
      }}
      className="org-switcher"
    >
      {organizations.map((org) => (
        <option key={org.id} value={org.id}>
          {org.name}
        </option>
      ))}
      <option value={CREATE_ORG_VALUE}>+ Create new organization</option>
    </select>
  );
}
