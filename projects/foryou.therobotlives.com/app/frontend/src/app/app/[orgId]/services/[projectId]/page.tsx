"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import {
  OrgApiError,
  listServiceLists,
  listServices,
  type OrgList,
} from "@/lib/org-api";
import { EmptyState, ErrorPanel, SkeletonRows } from "@/components/admin/ui";
import { ListsTable } from "@/components/org/service-tables";
import { Breadcrumb } from "@/components/org/breadcrumb";

export default function OrgServiceListsPage() {
  const params = useParams<{ orgId: string; projectId: string }>();
  const { orgId, projectId } = params;

  const [lists, setLists] = useState<OrgList[]>([]);
  const [serviceName, setServiceName] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [errorStatus, setErrorStatus] = useState<number | null>(null);

  useEffect(() => {
    if (!orgId || !projectId) return;
    let cancelled = false;
    setLoading(true);
    setError(null);
    setErrorStatus(null);

    Promise.all([
      listServiceLists(orgId, projectId),
      listServices(orgId).catch(() => null),
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
        setErrorStatus(e instanceof OrgApiError ? e.status : null);
        setError(e instanceof Error ? e.message : "Failed to load lists");
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, [orgId, projectId]);

  const crumbs = [
    { href: `/app/${orgId}`, label: "Dashboard" },
    { label: serviceName ?? "Site" },
  ];

  return (
    <div style={{ maxWidth: 960, margin: "2rem auto", padding: "0 1.25rem" }}>
      <Breadcrumb items={crumbs} />

      {loading ? (
        <SkeletonRows count={5} />
      ) : error && errorStatus === 403 ? (
        <ErrorPanel message="Access denied — you do not have permission to view this site." />
      ) : error ? (
        <ErrorPanel message={error} />
      ) : (
        <>
          <h1 className="sg-section-heading">{serviceName ?? "Lists"}</h1>
          {lists.length === 0 ? (
            <EmptyState title="No lists yet" message="Lists for this site will appear here once created." />
          ) : (
            <ListsTable lists={lists} hrefFor={(l) => `/app/${orgId}/services/${projectId}/lists/${l.id}`} />
          )}
        </>
      )}
    </div>
  );
}
