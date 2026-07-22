"use client";

import { useState, useEffect } from "react";
import { api } from "@/lib/api";

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
    api.adminListOrganizations(page).then((res) => {
      setOrgs(res.organizations);
      setTotal(res.total);
      setLoading(false);
    }).catch(() => setLoading(false));
  }, [page]);

  if (loading) return <p className="sg-admin-loading">Loading...</p>;

  return (
    <div>
      <h1 className="sg-section-heading">Organizations ({total})</h1>
      <table className="sg-table">
        <thead>
          <tr>
            <th>Name</th>
            <th>Slug</th>
            <th>Created</th>
          </tr>
        </thead>
        <tbody>
          {orgs.map((o) => (
            <tr key={o.id}>
              <td>{o.name}</td>
              <td>{o.slug}</td>
              <td>{new Date(o.created_at).toLocaleDateString()}</td>
            </tr>
          ))}
        </tbody>
      </table>
      <div className="sg-pagination">
        <button className="sg-btn sg-btn--outline sg-btn--sm" disabled={page <= 1} onClick={() => setPage(page - 1)}>Prev</button>
        <span className="sg-pagination__status">Page {page}</span>
        <button className="sg-btn sg-btn--outline sg-btn--sm" disabled={orgs.length < 50} onClick={() => setPage(page + 1)}>Next</button>
      </div>
    </div>
  );
}
