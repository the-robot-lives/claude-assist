'use client';

import { useAuth } from '@/context/auth';
import { useOrg } from '@/context/org';
import { useRouter } from 'next/navigation';
import { useEffect } from 'react';
import { userNeedsProfile, userPendingApproval } from '@/lib/auth-flow';

export default function AppPage() {
  const { user, loading: authLoading } = useAuth();
  const { organizations, loading: orgLoading } = useOrg();
  const router = useRouter();

  useEffect(() => {
    if (!authLoading && !user) {
      router.replace('/login');
    } else if (!authLoading && userNeedsProfile(user)) {
      router.replace('/complete-registration');
    } else if (!authLoading && userPendingApproval(user)) {
      router.replace('/pending-approval');
    } else if (!authLoading && !orgLoading && user && organizations.length === 0) {
      router.replace('/studio');
    } else if (!authLoading && !orgLoading && user && organizations.length === 1) {
      router.replace(`/app/${organizations[0].id}`);
    }
  }, [user, authLoading, orgLoading, organizations, router]);

  if (authLoading || orgLoading) return <div>Loading...</div>;
  if (!user) return null;

  if (organizations.length <= 1) return null;

  return (
    <div style={{ maxWidth: 600, margin: '2rem auto', padding: '0 1rem' }}>
      <h1>Your Organizations</h1>
      <ul style={{ listStyle: 'none', padding: 0 }}>
        {organizations.map((org) => (
          <li key={org.id} style={{ marginBottom: '1rem' }}>
            <a
              href={`/app/${org.id}`}
              style={{ display: 'block', padding: '1rem', border: '1px solid #ccc', borderRadius: '8px', textDecoration: 'none' }}
            >
              <strong>{org.name}</strong>
              <span style={{ marginLeft: '0.5rem', color: '#666' }}>({org.role})</span>
            </a>
          </li>
        ))}
      </ul>
    </div>
  );
}
