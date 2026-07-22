"use client";

import { useState, useEffect } from "react";
import { api } from "@/lib/api";
import { Button, Spinner } from "@/components/ui";

interface AdminOrg {
  id: string;
  slug: string;
  name: string;
  created_at: string;
}

export default function AdminOrgsPage() {
  const [orgs, setOrgs] = useState<AdminOrg[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api
      .adminListOrganizations(page)
      .then((res) => {
        setOrgs(res.organizations);
        setTotal(res.total);
        setLoading(false);
      })
      .catch(() => setLoading(false));
  }, [page]);

  if (loading) {
    return (
      <div className="flex items-center justify-center gap-2 p-16 text-text-muted">
        <Spinner size={20} />
        <span className="text-sm">Loading…</span>
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-4xl px-4 py-10">
      <h1 className="mb-4 text-2xl font-bold text-text">
        Organizations <span className="text-text-muted">({total})</span>
      </h1>

      <div className="overflow-x-auto rounded-lg border border-border bg-surface shadow-sm">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border text-left text-text-secondary">
              <th className="px-3 py-2 font-medium">Name</th>
              <th className="px-3 py-2 font-medium">Slug</th>
              <th className="px-3 py-2 font-medium">Created</th>
            </tr>
          </thead>
          <tbody>
            {orgs.map((o) => (
              <tr key={o.id} className="border-b border-border last:border-0 text-text">
                <td className="px-3 py-2">{o.name}</td>
                <td className="px-3 py-2 font-mono text-text-secondary">{o.slug}</td>
                <td className="px-3 py-2 text-text-secondary">{new Date(o.created_at).toLocaleDateString()}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="mt-4 flex items-center gap-3">
        <Button variant="outline" size="sm" disabled={page <= 1} onClick={() => setPage(page - 1)}>
          Prev
        </Button>
        <span className="text-sm text-text-muted">Page {page}</span>
        <Button variant="outline" size="sm" disabled={orgs.length < 50} onClick={() => setPage(page + 1)}>
          Next
        </Button>
      </div>
    </div>
  );
}
