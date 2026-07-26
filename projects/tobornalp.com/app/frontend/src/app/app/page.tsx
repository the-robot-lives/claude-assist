'use client';

import { useAuth } from '@/context/auth';
import { useOrg } from '@/context/org';
import { useRouter, useSearchParams } from 'next/navigation';
import { Suspense, useEffect, useState } from 'react';
import { api } from '@/lib/api';
import { userPendingApproval } from '@/lib/auth-flow';
import { Btn, FieldLabel, Input, Spinner } from '@/components/ui';

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

function LoadingScreen() {
  return (
    <div className="flex min-h-[40dvh] items-center justify-center gap-2 text-faint">
      <Spinner size={20} />
      <span className="text-[12px]">loading…</span>
    </div>
  );
}

export default function AppPage() {
  return (
    <Suspense fallback={<LoadingScreen />}>
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

  if (authLoading || orgLoading) return <LoadingScreen />;
  if (!user) return null;

  if (organizations.length === 1 && !createMode) {
    router.push(`/app/${organizations[0].id}`);
    return null;
  }

  const hasOrgs = organizations.length > 0;
  const canCreate = !userPendingApproval(user);

  return (
    <div className="mx-auto max-w-xl px-4 py-10">
      <h1 className="mb-6 text-[13px] font-bold uppercase tracking-[0.1em] text-ink">
        {hasOrgs ? 'your organizations' : 'welcome'}
      </h1>

      {hasOrgs ? (
        <ul className="mb-8 flex flex-col gap-2.5">
          {organizations.map((org) => (
            <li key={org.id}>
              <a
                href={`/app/${org.id}`}
                className="flex items-center justify-between rounded-panel border border-line bg-panel px-4 py-3 text-ink no-underline shadow-card transition-colors hover:border-line2 hover:bg-panel2 focus:outline-none focus-visible:ring-2 focus-visible:ring-acc/40"
              >
                <span className="font-bold">{org.name}</span>
                {org.role && <span className="text-[11px] text-faint">{org.role}</span>}
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
      <p className="text-[12px] text-mut">
        your account is registered and waiting for approval. you can create an
        organization once it&apos;s approved.
      </p>
    );
  }

  if (hasOrgs && !open) {
    return (
      <Btn variant="default" onClick={() => setOpen(true)}>
        + create organization
      </Btn>
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
    <div className={hasOrgs ? 'mt-4' : undefined}>
      <p className="text-[12px] text-mut">
        {hasOrgs
          ? 'create another organization — you’ll be its owner.'
          : 'you’re not part of an organization yet. create one to get started — you’ll be its owner and can invite your team.'}
      </p>
      <form onSubmit={submit} className="mt-4 flex flex-col gap-3">
        <FieldLabel label="organization name" htmlFor="org-name" required>
          <Input
            id="org-name"
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Acme Inc."
            className="rounded-card border-line2 bg-ground"
            autoFocus
          />
        </FieldLabel>
        <FieldLabel label="url slug" htmlFor="org-slug">
          <Input
            id="org-slug"
            type="text"
            value={effectiveSlug}
            onChange={(e) => {
              setSlugTouched(true);
              setSlug(slugify(e.target.value));
            }}
            placeholder="acme"
            className="rounded-card border-line2 bg-ground font-mono"
          />
        </FieldLabel>
        {error ? <p className="text-[12px] text-err">[ERR] {error}</p> : null}
        <div className="flex items-center gap-3">
          <Btn variant="primary" type="submit" disabled={submitting || !name.trim()}>
            {submitting ? 'creating…' : 'create organization'}
          </Btn>
          {hasOrgs ? (
            <Btn type="button" variant="default" onClick={() => setOpen(false)} disabled={submitting}>
              cancel
            </Btn>
          ) : null}
        </div>
      </form>
    </div>
  );
}
