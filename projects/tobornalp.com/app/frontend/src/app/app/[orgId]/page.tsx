'use client';

import { useParams } from 'next/navigation';
import { useOrg } from '@/context/org';
import { EmptyState, SectionCard } from '@/components/ui';

export default function OrgDashboard() {
  const { orgId } = useParams<{ orgId: string }>();
  const { currentOrg } = useOrg();

  return (
    <div className="mx-auto max-w-4xl px-4 py-8">
      <header className="mb-6">
        <h1 className="text-2xl font-bold text-text">{currentOrg?.name || 'Organization'}</h1>
        <p className="mt-1 font-mono text-xs text-text-muted">{orgId}</p>
      </header>

      <SectionCard title="Dashboard">
        <EmptyState title="Nothing here yet">
          Your organization dashboard is coming soon. Use the navigation to jump into items,
          goals, and today’s plan.
        </EmptyState>
      </SectionCard>
    </div>
  );
}
