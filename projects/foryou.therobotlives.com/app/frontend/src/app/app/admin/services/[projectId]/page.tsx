"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useOrg } from "@/context/org";
import {
  AdminApiError,
  adminListLists,
  adminListServices,
  optInMode,
  type AdminList,
} from "@/components/admin/admin-fetch";
import { BackLink, Badge, EmptyState, ErrorPanel, OptInBadge, SkeletonRows } from "@/components/admin/ui";

export default function ServiceListsPage() {
  const params = useParams<{ projectId: string }>();
  const projectId = params.projectId;
  const { currentOrg, loading: orgLoading } = useOrg();

  const [lists, setLists] = useState<AdminList[]>([]);
  const [serviceName, setServiceName] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [errorStatus, setErrorStatus] = useState<number | null>(null);

  useEffect(() => {
    if (orgLoading) return;
    if (!currentOrg) {
      setLoading(false);
      return;
    }
    let cancelled = false;
    setLoading(true);
    setError(null);
    setErrorStatus(null);

    Promise.all([
      adminListLists(currentOrg.id, projectId),
      adminListServices(currentOrg.id).catch(() => null),
    ])
      .then(([listsRes, svcRes]) => {
        if (cancelled) return;
        setLists(listsRes.lists);
        const svcs = svcRes?.projects ?? svcRes?.organizations ?? [];
        const svc = svcs.find((p) => p.id === projectId);
        setServiceName(svc?.name ?? null);
      })
      .catch((e) => {
        if (cancelled) return;
        setErrorStatus(e instanceof AdminApiError ? e.status : null);
        setError(e instanceof Error ? e.message : "Failed to load lists");
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [currentOrg, orgLoading, projectId]);

  if (orgLoading || loading) {
    return (
      <div>
        <BackLink href="/app/admin/services" label="Back to services" />
        <SkeletonRows count={5} />
      </div>
    );
  }
  if (!currentOrg) {
    return <EmptyState title="No organization selected" message="Select an organization to view its services." />;
  }
  if (error && errorStatus === 403) {
    return (
      <div>
        <BackLink href="/app/admin/services" label="Back to services" />
        <ErrorPanel message="Access denied — you do not have permission to view this service." />
      </div>
    );
  }
  if (error) {
    return (
      <div>
        <BackLink href="/app/admin/services" label="Back to services" />
        <ErrorPanel message={error} />
      </div>
    );
  }

  return (
    <div>
      <BackLink href="/app/admin/services" label="Back to services" />
      <h1 className="sg-section-heading">{serviceName ?? "Lists"}</h1>

      {lists.length === 0 ? (
        <EmptyState title="No lists yet" message="Lists for this service will appear here once created." />
      ) : (
        <div className="sg-table--scroll">
          <table className="sg-table">
            <thead>
              <tr>
                <th>Name</th>
                <th>Slug</th>
                <th>Kind</th>
                <th>Opt-in</th>
                <th>Signups</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {lists.map((l) => {
                const href = `/app/admin/services/${projectId}/lists/${l.id}`;
                return (
                  <tr key={l.id}>
                    <td>
                      <Link href={href} className="sg-admin-nav-link" style={{ padding: 0 }}>
                        {l.name}
                      </Link>
                    </td>
                    <td className="sg-td-muted">{l.slug}</td>
                    <td>
                      <Badge tone="neutral">{l.kind}</Badge>
                    </td>
                    <td>
                      <OptInBadge mode={optInMode(l)} />
                    </td>
                    <td>{l.signup_count}</td>
                    <td>
                      {l.status === "archived" ? <Badge tone="muted">Archived</Badge> : <Badge tone="success">Active</Badge>}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
