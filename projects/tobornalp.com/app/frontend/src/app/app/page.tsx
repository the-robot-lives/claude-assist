'use client';

import { useAuth } from '@/context/auth';
import { useOrg } from '@/context/org';
import { useRouter, useSearchParams } from 'next/navigation';
import { Suspense, useEffect, useState } from 'react';
import { api } from '@/lib/api';
import { userPendingApproval } from '@/lib/auth-flow';

// Derive a URL-safe slug from a free-text org name. Editable by the user; the
// backend enforces uniqueness and returns a 422 we surface inline.
function slugify(value: string) {
  return value
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 48);
}

export default function AppPage() {
  return (
    <Suspense fallback={<div>Loading...</div>}>
      <AppHub />
    </Suspense>
  );
}

function AppHub() {
  const { user, loading: authLoading } = useAuth();
  const { organizations, loading: orgLoading } = useOrg();
  const router = useRouter();
  const searchParams = useSearchParams();
  // Explicit intent to manage/create orgs — set by the "New organization" nav
  // link. Without it, a single-org user is sent straight into their workspace.
  const createMode = searchParams.get('create') === '1';

  useEffect(() => {
    if (!authLoading && !user) {
      router.push('/login');
    }
  }, [user, authLoading, router]);

  if (authLoading || orgLoading) return <div>Loading...</div>;
  if (!user) return null;

  if (organizations.length === 1 && !createMode) {
    router.push(`/app/${organizations[0].id}`);
    return null;
  }

  const hasOrgs = organizations.length > 0;
  const canCreate = !userPendingApproval(user);

  return (
    <div style={{ maxWidth: 600, margin: '2rem auto', padding: '0 1rem' }}>
      <h1>{hasOrgs ? 'Your Organizations' : 'Welcome'}</h1>

      {hasOrgs ? (
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
      ) : null}

      <CreateOrgSection canCreate={canCreate} hasOrgs={hasOrgs} />
    </div>
  );
}

// Create-an-organization affordance. When the user has no org this is the
// primary onboarding action (form shown directly). When they already belong to
// one or more orgs, it collapses behind a button so they can spin up additional
// orgs (owner of many). Approved (active) users only — a pending user is
// normally routed to /pending-approval, so the guard here is defensive.
function CreateOrgSection({ canCreate, hasOrgs }: { canCreate: boolean; hasOrgs: boolean }) {
  const [open, setOpen] = useState(!hasOrgs);
  const [name, setName] = useState('');
  const [slug, setSlug] = useState('');
  const [slugTouched, setSlugTouched] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const effectiveSlug = slugTouched ? slug : slugify(name);

  if (!canCreate) {
    return (
      <p>
        Your account is registered and waiting for approval. You can create an
        organization once it&apos;s approved.
      </p>
    );
  }

  if (hasOrgs && !open) {
    return (
      <button
        type="button"
        onClick={() => setOpen(true)}
        style={{
          marginTop: '0.5rem',
          padding: '0.6rem 1.2rem',
          borderRadius: '8px',
          border: '1px solid #234e23',
          background: 'transparent',
          color: '#234e23',
          fontWeight: 600,
          fontSize: '0.95rem',
          cursor: 'pointer',
        }}
      >
        + Create organization
      </button>
    );
  }

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (submitting) return;
    const finalName = name.trim();
    const finalSlug = (slugTouched ? slug : slugify(name)).trim();
    if (!finalName || !finalSlug) {
      setError('Please enter an organization name.');
      return;
    }
    setSubmitting(true);
    setError(null);
    try {
      const { organization } = await api.createOrganization(finalSlug, finalName);
      // Hard navigate so AuthProvider/OrgProvider rehydrate from /auth/me,
      // which now includes the new org (caller is its owner).
      window.location.href = `/app/${organization.id}`;
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Could not create organization.';
      setError(message);
      setSubmitting(false);
    }
  };

  return (
    <div style={{ marginTop: hasOrgs ? '1rem' : 0 }}>
      <p style={{ color: '#444' }}>
        {hasOrgs
          ? 'Create another organization — you’ll be its owner.'
          : 'You’re not part of an organization yet. Create one to get started — you’ll be its owner and can invite your team.'}
      </p>
      <form onSubmit={submit} style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem', marginTop: '1rem' }}>
        <label style={{ display: 'flex', flexDirection: 'column', gap: '0.25rem' }}>
          <span style={{ fontWeight: 600 }}>Organization name</span>
          <input
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Acme Inc."
            autoFocus
            style={{ padding: '0.6rem', border: '1px solid #ccc', borderRadius: '8px', fontSize: '1rem' }}
          />
        </label>
        <label style={{ display: 'flex', flexDirection: 'column', gap: '0.25rem' }}>
          <span style={{ fontWeight: 600 }}>URL slug</span>
          <input
            type="text"
            value={effectiveSlug}
            onChange={(e) => {
              setSlugTouched(true);
              setSlug(slugify(e.target.value));
            }}
            placeholder="acme"
            style={{ padding: '0.6rem', border: '1px solid #ccc', borderRadius: '8px', fontSize: '1rem' }}
          />
        </label>
        {error ? <p style={{ color: '#b00020', margin: 0 }}>{error}</p> : null}
        <div style={{ display: 'flex', gap: '0.75rem', alignItems: 'center' }}>
          <button
            type="submit"
            className="sg-btn sg-btn--black"
            disabled={submitting || !name.trim()}
            style={{
              padding: '0.7rem 1.4rem',
              borderRadius: '8px',
              border: 'none',
              background: '#234e23',
              color: '#fff',
              fontWeight: 600,
              fontSize: '1rem',
              cursor: submitting ? 'default' : 'pointer',
              opacity: submitting || !name.trim() ? 0.6 : 1,
            }}
          >
            {submitting ? 'Creating…' : 'Create organization'}
          </button>
          {hasOrgs ? (
            <button
              type="button"
              onClick={() => setOpen(false)}
              disabled={submitting}
              style={{ background: 'none', border: 'none', color: '#666', cursor: 'pointer', fontSize: '0.95rem' }}
            >
              Cancel
            </button>
          ) : null}
        </div>
      </form>
    </div>
  );
}
