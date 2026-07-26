'use client';

import { useParams } from 'next/navigation';
import { useOrg } from '@/context/org';
import { EmptyState, SectionCard } from '@/components/ui';

export default function OrgDashboard() {
  const { orgId } = useParams<{ orgId: string }>();
  const { currentOrg } = useOrg();

  return (
    <div className="app-content">
      <header>
        <h1 className="text-[19px] font-bold leading-snug text-ink">{currentOrg?.name || 'organization'}</h1>
        <p className="mt-1 text-[11px] text-faint">{orgId}</p>
      </header>

      <SectionCard title="dashboard">
        <EmptyState title="nothing here yet">
          your organization dashboard is coming soon. use the navigation to jump into items,
          goals, and today’s plan.
        </EmptyState>
      </SectionCard>
    </div>
  );
}
